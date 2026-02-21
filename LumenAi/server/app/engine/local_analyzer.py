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
    # Audio
    ".mp3", ".wav", ".m4a", ".ogg", ".flac", ".aac", ".opus", ".wma",
    # Video (Whisper extracts the audio track)
    ".mp4", ".mov", ".avi", ".mkv", ".webm", ".wmv", ".flv", ".3gp",
}

# Documents & text — handled by MarkItDown + raw fallback
TEXT_EXTRACTABLE = {
    # Documents
    ".pdf", ".doc", ".docx", ".ppt", ".pptx", ".xls", ".xlsx",
    # Text
    ".txt", ".md", ".markdown", ".rtf", ".csv",
    # Web
    ".html", ".htm", ".xml",
}


class LocalAnalyzer:
    """
    Fallback analyzer using Whisper (local STT) + Ollama (local LLM).
    Used when Gemini API is unavailable (rate limit / quota exceeded).
    """

    def __init__(self):
        self.md = MarkItDown()
        self.ollama_model = os.getenv("OLLAMA_MODEL", "llama3.2")
        self.whisper_model_name = os.getenv("WHISPER_MODEL", "base")
        self._whisper_model = None  # Lazy-load

    def _get_whisper_model(self):
        """Lazy-load Whisper model on first use."""
        if self._whisper_model is None:
            if not WHISPER_AVAILABLE:
                raise RuntimeError("openai-whisper is not installed. Run: pip install openai-whisper")
            print(f"  🎙️ Loading Whisper model '{self.whisper_model_name}' (first-time download may take a moment)...")
            self._whisper_model = whisper.load_model(self.whisper_model_name)
        return self._whisper_model

    def _transcribe_audio(self, path: str) -> str:
        """Transcribes an audio/video file to text using Whisper."""
        model = self._get_whisper_model()
        print(f"  🎙️ Transcribing audio: {os.path.basename(path)}")
        result = model.transcribe(path)
        return result.get("text", "")

    def _extract_text(self, path: str) -> str:
        """Extracts text from a document using MarkItDown."""
        print(f"  📝 Extracting text: {os.path.basename(path)}")
        result = self.md.convert(path)
        return result.text_content or ""

    def _build_prompt(self, content_text: str, syllabus_context: str) -> str:
        today_date = datetime.now().strftime("%Y-%m-%d")
        content_preview = content_text[:300].replace('"', '\\"').replace('\n', ' ')
        lecture_body = content_text[:12000]
        syllabus_body = syllabus_context[:3000] if syllabus_context else "None."

        return f"""You are an academic analysis API. Respond ONLY with a JSON object. Do not add any text before or after the JSON.

Today: {today_date}

=== LECTURE CONTENT TO ANALYZE ===
{lecture_body}

=== SYLLABUS CONTEXT ===
{syllabus_body}

=== TASK ===
Analyze the lecture content above. Generate the following JSON object with real content derived from the lecture:

{{
  "summary": "<write a 2-3 paragraph summary of the lecture content>",
  "topics": ["<main topic from lecture>", "<second topic>", "<third topic>"],
  "flashcards": [
    {{"front": "<key term from lecture>", "back": "<its definition or explanation>"}},
    {{"front": "<another term>", "back": "<its definition>"}}
  ],
  "quiz_questions": [
    {{
      "question": "<a multiple choice question about the lecture content>",
      "options": ["<option A>", "<option B>", "<option C>", "<option D>"],
      "correct_answer": "<the correct option text>",
      "explanation": "<why it is correct>"
    }}
  ],
  "mind_map": {{
    "nodes": [{{"id": 1, "label": "<central topic>"}}, {{"id": 2, "label": "<subtopic>"}}, {{"id": 3, "label": "<another subtopic>"}}],
    "edges": [{{"from": 1, "to": 2}}, {{"from": 1, "to": 3}}]
  }},
  "code_snippets": [],
  "extracted_tasks": [],
  "teacher_questions": ["<any questions the teacher asked>"],
  "important_dates": [],
  "transcript": "{content_preview}"
}}

Output the JSON now. Start with {{ and end with }}. Nothing else."""




    async def analyze(self, file_paths: list[str], syllabus_context: str = "") -> str:
        """
        Main entry point. Mirrors LectureAnalyzer.analyze_multimodal() interface.
        Returns JSON string on success.
        """
        if not OLLAMA_AVAILABLE:
            raise RuntimeError("Ollama is not installed. Run: pip install ollama && ollama serve")

        content_parts = []

        for path in file_paths:
            ext = os.path.splitext(path)[1].lower()
            print(f"  📂 Processing file: {os.path.basename(path)} (ext='{ext}')")
            try:
                if ext in AUDIO_EXTENSIONS:
                    transcript = self._transcribe_audio(path)
                    if transcript.strip():
                        content_parts.append(f"[AUDIO TRANSCRIPT]\n{transcript}")
                    else:
                        print(f"  ⚠️ Whisper returned empty transcript for {path}")
                else:
                    # Try MarkItDown first
                    try:
                        text = self._extract_text(path)
                    except Exception as md_err:
                        print(f"  ⚠️ MarkItDown failed ({md_err}), trying raw read...")
                        text = ""

                    # Fallback: read as raw text if MarkItDown gave nothing
                    if not text or not text.strip():
                        try:
                            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                                raw_text = f.read()
                            # Reject binary content: check if > 70% of chars are printable ASCII
                            printable = sum(1 for c in raw_text if c.isprintable() or c in '\n\r\t')
                            ratio = printable / max(len(raw_text), 1)
                            if ratio > 0.7:
                                text = raw_text
                                print(f"  📄 Raw text fallback: {len(text)} chars ({ratio:.0%} printable)")
                            else:
                                print(f"  ❌ Raw content appears binary ({ratio:.0%} printable), skipping")
                        except Exception as raw_err:
                            print(f"  ❌ Raw read also failed: {raw_err}")


                    if text and text.strip():
                        content_parts.append(f"[DOCUMENT CONTENT]\n{text}")
                    else:
                        print(f"  ❌ No content extracted from: {path}")

            except Exception as e:
                print(f"  ⚠️ Could not process {path}: {e}")



        if not content_parts:
            raise ValueError("No content could be extracted from the provided files.")

        combined_content = "\n\n".join(content_parts)
        print(f"  📝 Combined content size: {len(combined_content)} chars")
        print(f"  📝 Content preview (first 200): {combined_content[:200]}")
        
        # Rebuild prompt with content confirmed
        prompt = self._build_prompt(combined_content, syllabus_context)
        print(f"  📤 Prompt size: {len(prompt)} chars")

        print(f"  🤖 Sending to local Ollama model: {self.ollama_model}")


        # Ollama call using system+user message roles for best instruction-following
        max_retries = 2
        last_error = None
        for attempt in range(max_retries):
            try:
                response = ollama_client.chat(
                    model=self.ollama_model,
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a JSON API. You ONLY output valid JSON. Never add any text outside the JSON object."
                        },
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    format="json",  # Native JSON mode — guarantees valid, complete JSON output
                    options={
                        "temperature": 0.1,
                        "num_predict": 4096,  # Allow up to 4096 tokens output (default was ~512)
                    }
                )

                result_text = response["message"]["content"]
                print(f"  ✅ Local LLM responded ({len(result_text)} chars)")
                print(f"  📋 Response preview: {result_text[:500]}")
                return result_text

            except Exception as e:
                print(f"  ⚠️ Ollama Error (Attempt {attempt + 1}): {e}")
                last_error = e
                time.sleep(3)

        raise RuntimeError(f"Local LLM failed after {max_retries} attempts: {last_error}")
