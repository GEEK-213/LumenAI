import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()
my_key = os.getenv("OPENAI_API_KEY")

client = OpenAI(api_key=my_key)

audio_file_name = "test_audio.mp3" 

print(f"Opening {audio_file_name}...")

with open(audio_file_name, "rb") as audio:
    result = client.audio.transcriptions.create(
        model="whisper-1", 
        file=audio,
        response_format="text"
    )

print("\n--- DONE! HERE IS YOUR TEXT ---")
print(result)