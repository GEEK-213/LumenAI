import os
import aiofiles
import logging
from gtts import gTTS
import uuid
import tempfile
from fastapi import HTTPException

logger = logging.getLogger(__name__)

class AudioService:
    def __init__(self):
        self.output_dir = os.path.join(tempfile.gettempdir(), "lumencasts")
        os.makedirs(self.output_dir, exist_ok=True)
    
    async def generate_podcast_audio(self, transcript: str) -> str:
        """
        Takes an LLM-generated podcast script (transcript) and
        converts it to a temporary .mp3 audio file using Google TTS.
        Returns the absolute filepath to the MP3.
        """
        if not transcript or not transcript.strip():
            raise HTTPException(status_code=400, detail="Cannot generate audio from empty transcript.")

        try:
            # We run gTTS blocking code in a thread to prevent freezing the FastAPI asyncio event loop
            file_path = os.path.join(self.output_dir, f"podcast_{uuid.uuid4().hex}.mp3")
            
            # Using ThreadPoolExecutor implicitly by utilizing asyncio to run synchronous functions
            import asyncio
            loop = asyncio.get_event_loop()
            
            def create_mp3():
                tts = gTTS(text=transcript, lang='en', slow=False)
                tts.save(file_path)
            
            await loop.run_in_executor(None, create_mp3)
            logger.info(f"🎙️ Podcast audio successfully generated: {file_path}")
            
            return file_path
        
        except Exception as e:
            logger.error(f"❌ Failed to generate TTS podcast: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=f"Audio generation failed: {str(e)}")
