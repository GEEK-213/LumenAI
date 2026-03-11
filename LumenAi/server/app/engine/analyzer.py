import os
import time
import json
from datetime import datetime
from google import genai
from google.genai import types
from markitdown import MarkItDown
from app.config import Config


class RateLimitError(Exception):
    """Raised when Gemini API is rate-limited or quota exceeded."""
    pass


class LectureAnalyzer:
    def __init__(self):
        # Initialize Gemini Client
        self.client = genai.Client(api_key=Config.GEMINI_API_KEY)
        self.md = MarkItDown()

    async def prepare_content(self, file_paths: list[str], syllabus_context: str = "") -> list:
        """
        Extracts content from uploaded files (via Gemini Native Support or MarkItDown)
        Returns the fundamental `contents` list to be reused across different prompt generators.
        This allows us to upload/process the file ONCE, and query it MULTIPLE times.
        """
        NATIVE_SUPPORT = {".mp3", ".mp4", ".wav", ".mov"}
        contents = []

        # 1. Ground Truth - Syllabus Context goes first
        if syllabus_context:
            contents.append(f"---\nSYLLABUS CONTEXT:\n{syllabus_context[:50000]}\n---")

        # 2. Append all files
        for path in file_paths:
            ext = os.path.splitext(path)[1].lower()
            
            if ext in NATIVE_SUPPORT:
                print(f"  📤 Uploading Native Media: {os.path.basename(path)}")
                try:
                    file = self.client.files.upload(file=path)
                    # Wait for Google's infrastructure to process the video/audio
                    # Use async sleep to avoid blocking the FastAPI event loop
                    import asyncio
                    while file.state.name == "PROCESSING":
                        await asyncio.sleep(2)
                        file = self.client.files.get(name=file.name)
                    contents.append(file)
                except Exception as e:
                    print(f"  ❌ Gemini Upload Failed: {e}")
            else:
                print(f"  📝 Converting Document to Text: {os.path.basename(path)}")
                try:
                    result = self.md.convert(path)
                    file_text = f"\n\n--- START OF DOCUMENT: {os.path.basename(path)} ---\n{result.text_content}\n--- END OF DOCUMENT ---"
                    contents.append(file_text)
                except Exception as e:
                    print(f"  ⚠️ Conversion failed for {path}: {e}")
                    
        return contents

    async def _execute_prompt(self, contents: list, instructions: str) -> str:
        """
        Internal helper to execute the prompt against Gemini LLM.
        Handles API Rate Limits and Quota Exhaustion gracefully.
        Uses async sleep to avoid blocking the FastAPI event loop.
        """
        import asyncio
        # We prepend the instruction to the list of contents (which might contain Video clips)
        prompted_contents = [instructions] + contents
        max_retries = 3
        last_error = None
        
        for i in range(max_retries):
            try:
                response = self.client.models.generate_content(
                    model="gemini-2.5-flash", 
                    contents=prompted_contents,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_modalities=["TEXT"]
                    )
                )
                return response.text
            except Exception as e:
                print(f"  ⚠️ Gemini Error (Attempt {i+1}): {e}")
                error_str = str(e)
                # If we get rate limited, exponential backoff and retry
                if "429" in error_str or "503" in error_str or "quota" in error_str.lower():
                    last_error = e
                    await asyncio.sleep((2 ** i) + 5)
                else:
                    raise e
                    
        raise RateLimitError(f"Gemini rate limited after {max_retries} attempts: {last_error}")


    async def generate_initial_view(self, contents: list) -> str:
        """
        METHOD 1: Fast Response Initial View.
        Goal: Summarize text into 3 paragraphs and extract 5-8 key topics.
        Returns: strict JSON containing `summary`, `topics`, `transcript`, etc.
        This provides instant feedback to the user!
        """
        today_date = datetime.now().strftime("%Y-%m-%d")
        instructions = f"""
        You are 'Lumen AI', an advanced academic assistant.
        Today's date is {today_date}.
        
        GOAL: Summarize this text into 3 distinct paragraphs, extract 5-8 key topics, and generate a hierarchical mind map structure connecting these topics. Return AT LEAST 5 nodes in the mind map.
        
        OUTPUT FORMAT (Strict JSON):
        {{
            "summary": "A detailed, exam-focused summary in Markdown (3 distinct paragraphs).",
            "topics": ["Chapter 1", "Concept X"],
            "mind_map": {{
                "nodes": [{{"id": 1, "label": "Central Topic"}}],
                "edges": [{{"from": 1, "to": 2}}]
            }},
            "code_snippets": [
                {{"title": "Example", "language": "python", "code_content": "def foo(): pass"}}
            ],
            "extracted_tasks": [
                {{"title": "Task 1", "due_date": "YYYY-MM-DD or null"}}
            ],
            "teacher_questions": ["Question asked by teacher?"],
            "important_dates": ["2024-12-25"],
            "transcript": "Full transcript (if audio/video provided)"
        }}
        """
        return await self._execute_prompt(contents, instructions)


    async def generate_quiz(self, contents: list) -> str:
        """
        METHOD 2: Strict JSON Quiz Generator (Background Task).
        Goal: Generate exactly 5 MCQs based on this text.
        Background Task: Let the LLM take its time, minimizing 504 timeouts.
        """
        instructions = """
        You are strictly an MCQ generating API.
        
        GOAL: Generate EXACTLY 5 Multiple Choice Questions based on this text.
        
        CONSTRAINT: Output ONLY strict RAW JSON array. No markdown blocks.
        
        OUTPUT FORMAT (Strict JSON Array):
        [
            {{
                "question": "Exam-style MCQ question",
                "options": ["Option A", "Option B", "Option C", "Option D"],
                "correct_answer": "Option A", 
                "explanation": "Brief explanation"
            }}
        ]
        """
        return await self._execute_prompt(contents, instructions)


    async def generate_flashcards(self, contents: list) -> str:
        """
        METHOD 3: Strict JSON Flashcard Generator (Background Task).
        Goal: Generate 5 Front/Back flashcards.
        Background Task: Let the LLM take its time, minimizing 504 timeouts.
        """
        instructions = """
        You are strictly a Flashcard generating API.
        
        GOAL: Generate EXACTLY 5 Front/Back flashcards based on this text. Focus on definitions.
        
        CONSTRAINT: Output ONLY strict RAW JSON array. No markdown blocks.
        
        OUTPUT FORMAT (Strict JSON Array):
        [
            {{
                "front": "Term (e.g., Polymorphism)", 
                "back": "Definition based on syllabus/content"
            }}
        ]
        """
        return await self._execute_prompt(contents, instructions)

    async def generate_dynamic_quiz(self, contents: list, previous_questions: list) -> str:
        """
        Gamification (Phase 4): Generate 5 NOVEL MCQs avoiding previously asked questions.
        """
        import json
        avoid_str = json.dumps(previous_questions, indent=2) if previous_questions else "None"
        instructions = f"""
        You are strictly an MCQ generating API.
        
        GOAL: Generate EXACTLY 5 *NOVEL* Multiple Choice Questions based on this text.
        
        CRITICAL CONSTRAINT: DO NOT generate any questions similar to the following previously asked questions:
        {avoid_str}
        
        CONSTRAINT: Output ONLY strict RAW JSON array. No markdown blocks.
        
        OUTPUT FORMAT (Strict JSON Array):
        [
            {{
                "question": "Exam-style MCQ question",
                "options": ["Option A", "Option B", "Option C", "Option D"],
                "correct_answer": "Option A", 
                "explanation": "Brief explanation"
            }}
        ]
        """
        return await self._execute_prompt(contents, instructions)

    async def generate_dynamic_flashcards(self, contents: list, previous_fronts: list) -> str:
        """
        Gamification (Phase 4): Generate 5 NOVEL Flashcards avoiding previously generated concepts.
        """
        import json
        avoid_str = json.dumps(previous_fronts, indent=2) if previous_fronts else "None"
        instructions = f"""
        You are strictly a Flashcard generating API.
        
        GOAL: Generate EXACTLY 5 *NOVEL* Front/Back flashcards based on this text. Focus on definitions.
        
        CRITICAL CONSTRAINT: DO NOT generate flashcards for the following terms which the user already knows:
        {avoid_str}
        
        CONSTRAINT: Output ONLY strict RAW JSON array. No markdown blocks.
        
        OUTPUT FORMAT (Strict JSON Array):
        [
            {{
                "front": "Term (e.g., Polymorphism)", 
                "back": "Definition based on syllabus/content"
            }}
        ]
        """
        return await self._execute_prompt(contents, instructions)

    async def generate_podcast_script(self, contents: list) -> str:
        """
        Phase 5: Generate a LumenCast audio script from the lecture materials.
        """
        instructions = """
        You are a talented scriptwriter for a deeply engaging educational podcast.
        
        GOAL: Write a 2-host conversational podcast script (Host 1: Alex, Host 2: Jamie) 
        explaining the key concepts of the provided lecture material.
        
        STYLE:
        - Conversational, enthusiastic, and insightful (like NPR's Planet Money or Stuff You Should Know).
        - Use analogies and real-world examples.
        - The hosts seamlessly bounce off each other, occasionally asking rhetorical questions.
        - STRICTLY output spoken dialogue lines only. NO speaker labels (like Alex:, Jamie:) and NO stage directions ([laughs], etc).
        - Separate each host's spoken paragraph by a double newline so the TTS can pause naturally.
        - Do not explicitly say their names or introduce them, just jump right into the fascinating content.
        
        LENGTH: Aim for script text that would take about 2-3 minutes to read out loud.
        """
        return await self._execute_prompt(contents, instructions)