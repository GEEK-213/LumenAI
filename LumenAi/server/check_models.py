import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.environ.get("Gemini_API_key"))

print("Available models for your key:")
for m in client.models.list():
    print(f" - {m.name}")