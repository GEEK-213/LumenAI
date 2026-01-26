import os
import time
import random
from datetime import datetime
from google import genai
from google.genai import types
from markitdown import MarkItDown
from dotenv import load_dotenv

load_dotenv() 

class LectureAnalyzer:
    def __init__(self):
        api_key = os.environ.get("Gemini_API_key")
        self.client = genai.Client(api_key=api_key)
        self.md = MarkItDown()

    async def analyze_multimodal(self, file_paths: list[str]):
        today_date = datetime.now().strftime("%Y-%m-%d")
        
        # --- THE MASTER PROMPT ---
        # This is the "Brain" that tells Gemini what to do with all the data.
        master_instructions = f"""
        You are an advanced academic assistant for 'Project Lumen'.
        Today's date is {today_date}.
        
        You will be provided with a mix of lecture materials (audio, video, or document text).
        Your goal is to cross-reference ALL provided materials to create a study guide.
        
        RETURN A STRICT JSON OBJECT WITH:
        - "summary": A professional overview of the entire lecture.
        - "topics": Key concepts/chapters discussed.
        - "tasks": Any assignments or deadlines. Format: {{"task_name": "...", "due_date": "YYYY-MM-DD"}}.
        - "teacher_questions": Specific questions the teacher asked.
        - "important_dates": Exam dates or holidays mentioned.
        - "transcript": The full word-for-word transcription of the audio/video.
        
        If no data exists for a field, return [].
        """

        # This list holds EVERYTHING we send to Gemini
        contents = [master_instructions]

        NATIVE_SUPPORT = {".mp3", ".mp4", ".wav", ".pdf", ".mov"}

        for path in file_paths:
            ext = os.path.splitext(path)[1].lower()
            
            if ext in NATIVE_SUPPORT:
                # 1. Native Upload (Gemini "listens" and "watches" these)
                print(f"  📤 Uploading Native Media: {os.path.basename(path)}")
                file = self.client.files.upload(file=path)
                while file.state.name == "PROCESSING":
                    time.sleep(5)
                    file = self.client.files.get(name=file.name)
                contents.append(file)
            
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
                    model="gemini-2.0-flash", 
                    contents=contents,
                    config=types.GenerateContentConfig(response_mime_type="application/json")
                )
                return response.text
            except Exception as e:
                if "503" in str(e) or "429" in str(e):
                    wait_time = (2 ** attempt) + 15
                    print(f"  ⚠️ Model busy. Retrying in {int(wait_time)}s...")
                    time.sleep(wait_time)
                else:
                    raise e
        return None