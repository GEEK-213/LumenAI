import os
import logging
import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import asyncio

from app.routes import analysis, chat, ingestion, classroom
from app.tasks.classroom_sync import start_classroom_sync_job

load_dotenv()

# --- Logging Configuration ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("lumenai")

app = FastAPI(title="Lumen AI Brain")

# --- CORS Middleware (Restricted) ---
ALLOWED_ORIGINS = os.getenv(
    "CORS_ORIGINS",
    "*"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

# --- Global Exception Handler ---
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error on {request.method} {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal server error occurred. Please try again."},
    )

# --- Include Routers ---
app.include_router(analysis.router, prefix="/analysis", tags=["Analysis"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(ingestion.router, prefix="/ingestion", tags=["Ingestion"])
app.include_router(classroom.router, prefix="/classroom", tags=["Classroom Integration"])

# --- Health Check ---
@app.get("/health")
async def health_check():
    """Comprehensive health check — verifies Supabase connectivity."""
    checks = {"server": "ok"}
    
    # Check Supabase
    try:
        from app.database import supabase
        supabase.table("subjects").select("id").limit(1).execute()
        checks["database"] = "ok"
    except Exception as e:
        checks["database"] = f"error: {str(e)[:100]}"
    
    # Check Gemini API key presence
    checks["gemini_configured"] = bool(os.getenv("Gemini_API_key"))
    
    # Check JWT secret presence
    checks["jwt_configured"] = bool(os.getenv("SUPABASE_JWT_SECRET"))
    
    overall = "ok" if all(
        v == "ok" or v is True for v in checks.values()
    ) else "degraded"
    
    return {"status": overall, "checks": checks, "message": "Lumen AI Brain 🧠"}

# --- Startup Event ---
@app.on_event("startup")
async def startup_event():
    logger.info("🚀 Lumen AI Brain Initialized")
    logger.info("📡 Ready to receive data shards")
    
    # Warn about missing critical env vars
    if not os.getenv("SUPABASE_JWT_SECRET"):
        logger.warning("⚠️ SUPABASE_JWT_SECRET is not set! Auth middleware will reject all requests.")
    if not os.getenv("Gemini_API_key"):
        logger.warning("⚠️ Gemini_API_key is not set! AI analysis will fall back to Ollama only.")
    
    # Start the Google Classroom Sync background worker
    asyncio.create_task(start_classroom_sync_job())

# --- Entry Point ---
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
