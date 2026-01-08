import os
from fastapi import FastAPI, UploadFile, File, HTTPException
from google import genai
from google.genai import types
import shutil

app = FastAPI()

# GEMINI_API_KEY = os.getenv("Gemini_API_key")
client = genai.Client(api_key=os.environ.get("Gemini_API_key"))

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    # 1. Validate file type
    if not file.filename.endswith(".mp3"):
        raise HTTPException(status_code=400, detail="Only MP3 files are supported.")

    # 2. Save the uploaded file locally temporarily
    temp_path = f"temp_{file.filename}"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        # 3. Upload the file to Gemini's File API
        # The File API is recommended for audio files to avoid payload size limits
        uploaded_file = client.files.upload(file=temp_path)

        # 4. Generate the transcription
        # We use a prompt to tell Gemini exactly how to format the text
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[
                "Please provide a high-quality transcription of this audio. "
                "Identify different speakers if possible and use timestamps.",
                uploaded_file
            ]
        )

        return {
            "filename": file.filename,
            "transcript": response.text
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        # 5. Cleanup: Remove the temporary local file
        if os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)