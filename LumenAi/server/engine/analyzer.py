import os
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv() 

class LectureAnalyzer:
    def __init__(self):
        api_key = os.environ.get("Gemini_API_key")
        if not api_key:
            raise ValueError("Gemini_API_key not found in .env file!")
        self.client = genai.Client(api_key=api_key)

    async def analyze_audio(self, file_path: str):
        # 1. Upload the file
        uploaded_file = self.client.files.upload(file=file_path)

        # 2. Instructions for structured JSON output
        prompt = "Analyze this audio and return JSON with title, summary, key_points, quiz, and transcript keys."

        # 3. Use the correct model name 'gemini-2.0-flash-exp' or 'gemini-1.5-flash'
        # 'gemini-2.0-flash' might not be fully available in some regions yet
        response = self.client.models.generate_content(
            model="gemini-1.5-flash", 
            contents=[prompt, uploaded_file],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            )
        )
        
        return response.text