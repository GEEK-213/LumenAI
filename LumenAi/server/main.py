import os
import uuid
import uvicorn
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware # Added
from dotenv import load_dotenv
import asyncio # Added

from app.routes import analysis, chat, ingestion, classroom
from app.tasks.classroom_sync import start_classroom_sync_job # Added

load_dotenv()

app = FastAPI(title="Lumen AI Brain") # Modified to add title and keep original name

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allows all origins
    allow_credentials=True,
    allow_methods=["*"], # Allows all methods
    allow_headers=["*"], # Allows all headers
)

# --- Include Routers ---
app.include_router(analysis.router, prefix="/analysis", tags=["Analysis"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(ingestion.router, prefix="/ingestion", tags=["Ingestion"])
app.include_router(classroom.router, prefix="/classroom", tags=["Classroom Integration"])

# --- Routes ---

@app.get("/")
def health_check():
    return {"status": "ok", "message": "Lumen AI Brain is Online 🧠"}

# --- Startup Event ---
@app.on_event("startup")
async def startup_event():
    print("🚀 Lumen AI Brain Initialized...")
    print("📡 Ready to receive data shards...")
    # Start the Google Classroom Sync background worker
    asyncio.create_task(start_classroom_sync_job())

# --- Entry Point ---
if __name__ == "__main__":
    # Matches the port in your test script (8001)
    uvicorn.run(app, host="0.0.0.0", port=8001)
