import os
import time
import json
import random
from datetime import datetime
from google import genai
from google.genai import types
from markitdown import MarkItDown
from app.config import Config

class LectureAnalyzer:
    def __init__(self):
        self.client = genai.Client(api_key=Config.GEMINI_API_KEY)
        self.md = MarkItDown()

    async def analyze_multimodal(self, file_paths: list[str], syllabus_context: str = ""):
        today_date = datetime.now().strftime("%Y-%m-%d")
        
        # --- THE MASTER PROMPT ---
        master_instructions = f"""
        You are 'Lumen AI', an advanced academic assistant.
        Today's date is {today_date}.
        
        INPUTS:
        1. Lecture Media (Audio/Video/Text).
        2. SYLLABUS CONTEXT (Ground Truth): 
        "{syllabus_context[:50000] if syllabus_context else "No specific syllabus provided."}"
        (Note: If syllabus is provided, prioritize its definitions and terminology.)

        GOAL:
        Analyze the lecture. CROSS-REFERENCE it with the SYLLABUS CONTEXT.
        - If a topic in the lecture matches the syllabus, elaborate on it using syllabus definitions.
        - If the lecture contains "noise" (off-topic chat), IGNORE it unless it's a deadline.
        
        OUTPUT FORMAT:
        Return a STRICT JSON object with the following schema:
        {{
            "summary": "A detailed, exam-focused summary in Markdown.",
            "topics": ["Chapter 1", "Concept X"],
            "flashcards": [
                {{"front": "Term (e.g., Polymorphism)", "back": "Definition based on syllabus"}}
            ],
            "quiz_questions": [
                {{
                    "question": "Exam-style MCQ question",
                    "options": ["Option A", "Option B", "Option C", "Option D"],
                    "correct_answer": "Option A", 
                    "explanation": "Brief explanation"
                }}
            ],
            "mind_map": {{
                "nodes": [{{"id": 1, "label": "Central Topic"}}],
                "edges": [{{"from": 1, "to": 2}}]
            }},
            "code_snippets": [
                {{"title": "Example Function", "language": "python", "code_content": "def foo(): pass"}}
            ],
            "extracted_tasks": [
                {{"title": "Assignment 1", "due_date": "YYYY-MM-DD (or null)"}}
            ],
            "teacher_questions": ["Question asked by teacher?"],
            "important_dates": ["2024-12-25"],
            "transcript": "Full word-for-word transcript (if audio provided)"
        }}
        
        IMPORTANT:
        - Return ONLY valid JSON.
        - Do NOT wrap in markdown code blocks (e.g., ```json ... ```).
        - No conversational filler (e.g., "Here is the JSON").
        - If a field has no data, return an empty list/null.
        """

        # This list holds EVERYTHING we send to Gemini
        contents = [master_instructions]

        NATIVE_SUPPORT = {".mp3", ".mp4", ".wav", ".pdf", ".mov"}

        for path in file_paths:
            ext = os.path.splitext(path)[1].lower()
            
            if ext in NATIVE_SUPPORT:
                # 1. Native Upload (Gemini "listens" and "watches" these)
                print(f"  📤 Uploading Native Media: {os.path.basename(path)}")
                try:
                    file = self.client.files.upload(file=path)
                    while file.state.name == "PROCESSING":
                        time.sleep(2)
                        file = self.client.files.get(name=file.name)
                    contents.append(file)
                except Exception as e:
                    print(f"  ❌ Gemini Upload Failed: {e}")
            
            else:
                # 2. Text Extraction (Gemini "reads" these as Markdown)
                print(f"  📝 Converting Document to Text: {os.path.basename(path)}")
                try:
                    result = self.md.convert(path)
                    # We wrap the text in a clear header so Gemini knows which file it's from
                    file_text = f"\n\n--- START OF DOCUMENT: {os.path.basename(path)} ---\n{result.text_content}\n--- END OF DOCUMENT ---"
                    contents.append(file_text)
                except Exception as e:
                    print(f"  ⚠️ Conversion failed for {path}: {e}")

        # --- THE EXECUTION ---
        max_retries = 3
        for attempt in range(max_retries):
            try:
                # We send the WHOLE 'contents' list (Instructions + Media + Text)
                response = self.client.models.generate_content(
                    model="gemini-2.5-flash", 
                    contents=contents,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_modalities=["TEXT"]
                    )
                )
                return response.text
            except Exception as e:
                print(f"  ⚠️ Gemini Error (Attempt {attempt+1}): {e}")
                if "503" in str(e) or "429" in str(e):
                    time.sleep((2 ** attempt) + 5)
                    last_error = e
                else:
                    # Fatal error (e.g. 400 Bad Request, 401 Unauthorized), raise immediately
                    raise e
        
        # If we exhausted retries, raise the last error
        if last_error:
            raise last_error
        return None