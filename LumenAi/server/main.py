from fastapi import FastAPI, UploadFile, File, HTTPException
from engine.analyzer import LectureAnalyzer
from dotenv import load_dotenv
import shutil
import os
import json

# 1. Load environment variables
load_dotenv()

app = FastAPI()
analyzer = LectureAnalyzer()

@app.post("/lecture/analyze")
async def analyze_lecture(file: UploadFile = File(...)):
    # Validate file type
    if not file.filename.endswith(".mp3"):
        raise HTTPException(status_code=400, detail="Only MP3 files are supported.")

    temp_path = f"temp_{file.filename}"
    
    try:
        # Save the uploaded file locally
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Call your engine
        analysis_json_str = await analyzer.analyze_audio(temp_path)
        
        # Clean and return JSON
        clean_json = analysis_json_str.strip().replace("```json", "").replace("```", "")
        return json.loads(clean_json)

    except Exception as e:
        print(f"Engine Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Cleanup
        if os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)