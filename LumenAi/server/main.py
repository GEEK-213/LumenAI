import os
import uuid
import uvicorn
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks
from dotenv import load_dotenv

# Import your existing logic if available
try:
    from app.engine.analyzer import LectureAnalyzer
except ImportError:
    print("⚠️ Warning: Could not import LectureAnalyzer. AI features will be mocked.")
    LectureAnalyzer = None

load_dotenv()

app = FastAPI()

# --- Helper: Background Task ---
async def process_lecture_upload(file_name: str, title: str, user_id: str):
    """
    Simulates the long-running AI process in the background.
    """
    print(f"🦁 [Background] Processing started for: {title} ({file_name})")
    
    if LectureAnalyzer:
        # TODO: Here is where you will eventually:
        # 1. Save the file to disk/Supabase
        # 2. Run Whisper to get text
        # 3. Run Gemini to get notes
        pass
    
    await asyncio.sleep(2) # Simulate work
    print(f"✅ [Background] Analysis complete for: {title}")

# --- Routes ---

@app.get("/")
def health_check():
    return {"status": "ok", "message": "Lumen AI Brain is Online 🧠"}

@app.post("/analysis/process")
async def process_analysis(
    background_tasks: BackgroundTasks,
    # These match the fields sent by requests.post in your test script
    file: UploadFile = File(...),
    user_id: str = Form(...),
    title: str = Form(...),
    unit_id: Optional[str] = Form(None)
):
    """
    Receives a file upload + metadata from Flutter/Test Script.
    """
    print(f"\n📥 INCOMING REQUEST:")
    print(f"   - Title: {title}")
    print(f"   - User: {user_id}")
    print(f"   - File: {file.filename}")

    # Generate a tracking ID
    task_id = str(uuid.uuid4())

    # Start the "heavy lifting" in the background so the app doesn't freeze
    background_tasks.add_task(process_lecture_upload, file.filename, title, user_id)
    
    return {
        "status": "success",
        "message": "File received, processing started.",
        "data": {
            "task_id": task_id,
            "filename": file.filename,
            "status": "processing"
        }
    }

# --- Entry Point ---
if __name__ == "__main__":
    import asyncio
    # Matches the port in your test script (8001)
    uvicorn.run(app, host="0.0.0.0", port=8001)