"""
LumenAI Lecture Analyzer — Gemini Engine with API Key Rotation.

Architecture:
  1. Loads ALL Gemini API keys from Config.GEMINI_API_KEYS (comma-separated in .env)
  2. Tracks a rotating index so each new request starts with the next key in line (round-robin)
  3. On a 429/quota error, instantly rotates to the next key and retries
  4. If ALL keys are exhausted, raises RateLimitError so the caller can fall back to Ollama
  5. Uses await asyncio.sleep() for backoff — never blocks the FastAPI event loop
"""

import os
import asyncio
import json
import logging
from datetime import datetime
from google import genai
from google.genai import types
from markitdown import MarkItDown
from app.config import Config

logger = logging.getLogger(__name__)


class RateLimitError(Exception):
    """Raised when ALL Gemini API keys are rate-limited or quota exceeded."""
    pass


class LectureAnalyzer:
    """
    Primary AI engine using Google Gemini 2.5 Flash.
    Supports multi-key rotation to maximize free-tier throughput.
    """

    def __init__(self):
        # --- API Key Rotation State ---
        self.api_keys = Config.GEMINI_API_KEYS or []
        self.key_count = len(self.api_keys)

        if self.key_count == 0:
            raise ValueError("No Gemini API keys configured. Set GEMINI_KEYS or Gemini_API_key in .env")

        # Round-robin pointer — starts at 0, increments on each new request
        self._current_key_index = 0

        # Initialize the client with the first key
        self.client = genai.Client(api_key=self.api_keys[0])
        self.md = MarkItDown()

        logger.info(f"🔑 Gemini Key Rotation Engine initialized with {self.key_count} key(s)")

    def _rotate_client(self) -> str:
        """
        Advances the round-robin pointer to the next API key and
        rebuilds the Gemini client with that key.
        Returns the new key (truncated for logging).
        """
        self._current_key_index = (self._current_key_index + 1) % self.key_count
        new_key = self.api_keys[self._current_key_index]
        self.client = genai.Client(api_key=new_key)
        # Log only the last 6 characters for security
        return f"...{new_key[-6:]}"

    def _is_quota_error(self, error: Exception) -> bool:
        """
        Checks if an exception is a quota/rate-limit error (429, 503, RESOURCE_EXHAUSTED).
        These are the ONLY errors that trigger key rotation.
        Other errors (bad prompt, network timeout) are NOT retried with a new key.
        """
        error_str = str(error).lower()
        return any(signal in error_str for signal in [
            "429", "503", "resource_exhausted", "quota", "rate limit", "too many requests"
        ])

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
        Core prompt execution engine with API Key Rotation.

        Algorithm:
          1. Try the current key (up to 2 retries with exponential backoff)
          2. If the key throws a quota error (429/503/RESOURCE_EXHAUSTED):
             → Instantly rotate to the next key in the list
             → Reset retry counter for the new key
          3. If ALL keys have been tried and all are exhausted:
             → Raise RateLimitError (caller falls back to Ollama)
          4. Non-quota errors (bad prompt, network) are raised immediately

        This ensures the user's request survives even during peak usage
        by squeezing every drop of quota from all available keys.
        """
        prompted_contents = [instructions] + contents

        # How many retries per individual key before rotating
        RETRIES_PER_KEY = 2
        # Track how many keys we've fully exhausted
        keys_exhausted = 0
        last_error = None

        while keys_exhausted < self.key_count:
            current_key_preview = f"...{self.api_keys[self._current_key_index][-6:]}"
            
            for attempt in range(RETRIES_PER_KEY):
                try:
                    response = self.client.models.generate_content(
                        model="gemini-2.5-flash", 
                        contents=prompted_contents,
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                            response_modalities=["TEXT"]
                        )
                    )
                    return response.text  # ✅ Success — return immediately

                except Exception as e:
                    last_error = e

                    if self._is_quota_error(e):
                        # Quota error — backoff briefly then retry same key
                        backoff = (2 ** attempt) + 1  # 2s, 3s
                        logger.warning(
                            f"⚠️ Key {current_key_preview} quota hit "
                            f"(attempt {attempt + 1}/{RETRIES_PER_KEY}). "
                            f"Backing off {backoff}s..."
                        )
                        await asyncio.sleep(backoff)
                    else:
                        # Non-quota error (bad prompt, network) — don't rotate, just fail
                        logger.error(f"❌ Gemini non-quota error: {e}")
                        raise e

            # If we reach here, this key's retries are fully exhausted
            keys_exhausted += 1

            if keys_exhausted < self.key_count:
                # Rotate to the next key
                new_key_preview = self._rotate_client()
                logger.warning(
                    f"🔄 Key {current_key_preview} fully exhausted. "
                    f"Rotating to key {new_key_preview} "
                    f"({keys_exhausted}/{self.key_count} exhausted)"
                )
            else:
                logger.error(
                    f"🚨 ALL {self.key_count} Gemini keys exhausted! "
                    f"Raising RateLimitError for Ollama fallback."
                )

        # All keys tried and failed — let the caller fall back to Ollama
        raise RateLimitError(
            f"All {self.key_count} Gemini API key(s) exhausted after "
            f"{RETRIES_PER_KEY} retries each. Last error: {last_error}"
        )


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