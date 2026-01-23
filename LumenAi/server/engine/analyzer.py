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
        
        # Use the standard client setup for Gemini 2.5
        self.client = genai.Client(api_key=api_key)

    async def analyze_audio(self, file_path: str):
        # 1. Upload the file
        uploaded_file = self.client.files.upload(file=file_path)

        # 2. Refined Prompt for professional, high-level analysis
        prompt = """
        Analyze this audio recording with academic rigor and professional insight. 
        Provide a JSON response with exactly these keys:
        - "title": A sophisticated and evocative title.
        - "summary": A high-level, professional overview.
        - "key_points": An array of the most critical concepts.
        - "quiz": An array of challenging questions (with options and answer).
        - "transcript": A clean transcription of the audio.
        """

        # 3. USE THE MODEL FROM YOUR LIST: gemini-2.5-flash
        response = self.client.models.generate_content(
            model="gemini-2.5-flash", 
            contents=[prompt, uploaded_file],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            )
        )
        
        return response.text