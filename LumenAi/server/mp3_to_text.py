from fastapi import FastAPI
from models.base import Base
from routes import auth, song, lecture  # 1. Import the new lecture router
from database import engine

app = FastAPI()

# 2. Register the routers
app.include_router(auth.router, prefix='/auth')
app.include_router(song.router, prefix='/song')
app.include_router(lecture.router, prefix='/lecture') # This enables /lecture/analyze

# 3. Create database tables
Base.metadata.create_all(engine)

if __name__ == "__main__":
    import uvicorn
    # Running on 0.0.0.0 allows your Flutter app (on a phone/emulator) 
    # to connect to your local machine's IP.
    uvicorn.run(app, host="0.0.0.0", port=8000)