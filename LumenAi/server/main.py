import os
import uuid
import uvicorn
from typing import Optional
from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks
from dotenv import load_dotenv

from app.routes import analysis, chat, ingestion

load_dotenv()

app = FastAPI()

# --- Include Routers ---
app.include_router(analysis.router, prefix="/analysis", tags=["Analysis"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(ingestion.router, prefix="/ingestion", tags=["Ingestion"])

# --- Routes ---

@app.get("/")
def health_check():
    return {"status": "ok", "message": "Lumen AI Brain is Online 🧠"}

# --- Entry Point ---
if __name__ == "__main__":
    import asyncio
    # Matches the port in your test script (8001)
    uvicorn.run(app, host="0.0.0.0", port=8001)

# --- Entry Point ---
if __name__ == "__main__":
    import asyncio
    # Matches the port in your test script (8001)
    uvicorn.run(app, host="0.0.0.0", port=8001)