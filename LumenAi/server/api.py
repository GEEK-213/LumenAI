from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import ingestion, analysis, chat

app = FastAPI(title="Lumen AI Backend", version="2.0")

# CORS Configuration
# Allow Flutter app (running on localhost, emulators, or web) to connect
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Routes
app.include_router(ingestion.router, prefix="/ingestion", tags=["Ingestion"])
app.include_router(analysis.router, prefix="/analysis", tags=["Analysis"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])

@app.get("/")
def health_check():
    return {"status": "ok", "message": "Lumen AI Brain is Online 🧠"}

if __name__ == "__main__":
    import uvicorn
    # Host 0.0.0.0 is crucial for Android Emulator access (via 10.0.2.2)
    uvicorn.run(app, host="0.0.0.0", port=8001)
