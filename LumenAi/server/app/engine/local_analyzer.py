import os
import json
import re
import time
from datetime import datetime
from markitdown import MarkItDown

# Lazy imports to avoid crash if not installed
try:
    import whisper
    WHISPER_AVAILABLE = True
except ImportError:
    WHISPER_AVAILABLE = False
    print("⚠️ openai-whisper not installed. Audio fallback disabled.")

try:
    import ollama as ollama_client
    OLLAMA_AVAILABLE = True
except ImportError:
    OLLAMA_AVAILABLE = False
    print("⚠️ ollama not installed. Local LLM fallback disabled.")


# Audio & Video — all handled by Whisper
AUDIO_EXTENSIONS = {
    ".mp3", ".wav", ".m4a", ".ogg", ".flac", ".aac", ".opus", ".wma",
    ".mp4", ".mov", ".avi", ".mkv", ".webm", ".wmv", ".flv", ".3gp",
}


class LocalAnalyzer:
    """
    Fallback analyzer using Whisper (local STT) + Ollama (local LLM).
    Refactored to support Smart Chaining (Lazy Loading).
    """

    def __init__(self):
        self.md = MarkItDown()
        self.ollama_model = os.getenv("OLLAMA_MODEL", "llama3.2")
        self.whisper_model_name = os.getenv("WHISPER_MODEL", "base")
        self._whisper_model = None

    def _get_whisper_model(self):
        if self._whisper_model is None:
            if not WHISPER_AVAILABLE:
                raise RuntimeError("openai-whisper is not installed. Run: pip install openai-whisper")
            print(f"  🎙️ Loading Whisper model '{self.whisper_model_name}'...")
            self._whisper_model = whisper.load_model(self.whisper_model_name)
        return self._whisper_model

    def _transcribe_audio(self, path: str) -> str:
        model = self._get_whisper_model()
        print(f"  🎙️ Transcribing audio: {os.path.basename(path)}")
        result = model.transcribe(path)
        return result.get("text", "")

    def _extract_text(self, path: str) -> str:
        print(f"  📝 Extracting text: {os.path.basename(path)}")
        result = self.md.convert(path)
        extracted_text = result.text_content or ""
        
        # OCR Fallback for Scanned PDFs
        suffix = os.path.splitext(path)[1].lower()
        if suffix == '.pdf':
            words = [w for w in extracted_text.split() if w.isalpha() and len(w) > 2]
            if len(words) < 20:
                print("  ⚠️ MarkItDown found very little text. Attempting OCR fallback...")
                try:
                    import fitz
                    import pytesseract
                    from PIL import Image
                    import io

                    if os.name == 'nt':
                        tesseract_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
                        if os.path.exists(tesseract_path):
                            pytesseract.pytesseract.tesseract_cmd = tesseract_path

                    with fitz.open(path) as doc:
                        ocr_text = ""
                        for page_num in range(len(doc)):
                            page = doc.load_page(page_num)
                            pix = page.get_pixmap(dpi=150)
                            img_bytes = pix.tobytes("jpeg")
                            with Image.open(io.BytesIO(img_bytes)) as img:
                                ocr_text += pytesseract.image_to_string(img) + "\n\n"
                                
                    if len(ocr_text.strip()) > len(extracted_text.strip()):
                        print("  ✅ OCR Success!")
                        extracted_text = ocr_text
                except Exception as e:
                    print(f"  ⚠️ OCR Failed: {e}")
                    
        return extracted_text

    async def prepare_content(self, file_paths: list[str], syllabus_context: str = "") -> str:
        """
        Reads local files and returns a large concatenated string.
        (Mirrors new architecture of Gemini Analyzer).
        """
        if not OLLAMA_AVAILABLE:
            raise RuntimeError("Ollama is not installed. Run: pip install ollama && ollama serve")

        content_parts = []
        if syllabus_context:
            content_parts.append(f"[SYLLABUS CONTEXT]\n{syllabus_context[:50000]}")

        for path in file_paths:
            ext = os.path.splitext(path)[1].lower()
            try:
                if ext in AUDIO_EXTENSIONS:
                    transcript = self._transcribe_audio(path)
                    if transcript.strip():
                        content_parts.append(f"[AUDIO TRANSCRIPT]\n{transcript}")
                else:
                    try:
                        text = self._extract_text(path)
                    except Exception:
                        text = ""
                    # Fallback raw read
                    if not text.strip():
                        with open(path, "r", encoding="utf-8", errors="ignore") as f:
                            text = f.read()
                    if text.strip():
                        content_parts.append(f"[DOCUMENT CONTENT]\n{text}")
            except Exception as e:
                print(f"  ⚠️ Could not process {path}: {e}")

        combined_content = "\n\n".join(content_parts)
        if not combined_content.strip():
            raise ValueError("No content could be extracted.")
        return combined_content

    async def _execute_prompt(self, content_text: str, system_prompt: str, json_schema: str) -> str:
        """Helper to run ollama chat strictly returning JSON."""
        import asyncio
        # Trim content so we don't blow up context window on edge cases
        content_preview = content_text[:300].replace('"', '\\"').replace('\n', ' ')
        lecture_body = content_text[:40000] # Increased context limit for robust PDFs

        full_prompt = f"""
=== LECTURE CONTENT ===
{lecture_body}

=== INSTRUCTIONS ===
{system_prompt}

Output ONLY valid JSON matching this schema:
{json_schema}
"""
        max_retries = 2
        last_error = None
        for attempt in range(max_retries):
            try:
                response = ollama_client.chat(
                    model=self.ollama_model,
                    messages=[
                        {"role": "system", "content": "You are a JSON API. You ONLY output valid JSON. Never output conversational text outside the JSON."},
                        {"role": "user", "content": full_prompt}
                    ],
                    format="json", 
                    options={
                        "temperature": 0.1,
                        "num_predict": 2048, 
                    }
                )
                return response["message"]["content"]
            except Exception as e:
                print(f"  ⚠️ Ollama Error (Attempt {attempt + 1}): {e}")
                last_error = e
                await asyncio.sleep(3)

        raise RuntimeError(f"Local LLM failed after {max_retries} attempts: {last_error}")


    async def generate_initial_view(self, combined_content: str) -> str:
        system_prompt = "Summarize the text into 3 distinct paragraphs, extract 5-8 key topics, and generate a hierarchical mind map structure connecting these topics. Return AT LEAST 5 nodes in the mind map."
        json_schema = """
        {
            "summary": "markdown string",
            "topics": ["topic1", "topic2"],
            "mind_map": {
                "nodes": [{"id": 1, "label": "Central Topic"}],
                "edges": [{"from": 1, "to": 2}]
            },
            "code_snippets": [],
            "extracted_tasks": [],
            "teacher_questions": [],
            "important_dates": [],
            "transcript": "string"
        }
        """
        return await self._execute_prompt(combined_content, system_prompt, json_schema)


    async def generate_quiz(self, combined_content: str) -> str:
        system_prompt = "Generate EXACTLY 5 Multiple Choice Questions based on the text."
        json_schema = """
        [
            {
                "question": "question text",
                "options": ["A", "B", "C", "D"],
                "correct_answer": "A", 
                "explanation": "why"
            }
        ]
        """
        return await self._execute_prompt(combined_content, system_prompt, json_schema)

    async def generate_flashcards(self, combined_content: str) -> str:
        system_prompt = "Generate EXACTLY 5 Front/Back flashcards based on the text. Focus on definitions."
        json_schema = """
        [
            {
                "front": "Term", 
                "back": "Definition"
            }
        ]
        """
        return await self._execute_prompt(combined_content, system_prompt, json_schema)
