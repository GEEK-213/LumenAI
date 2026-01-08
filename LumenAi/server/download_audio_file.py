import os
from supabase import create_client, Client
from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import StreamingResponse
import io

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_ANON_KEY")
supabase: Client = create_client(url, key)

app = FastAPI()

@app.get("/download-audio/{file_name}")
async def download_audio(file_name: str):
    try:
        response = supabase.storage.from_("audio-bucket").download(file_name)
        
        return Response(
            content=response, 
            media_type="audio/mpeg",
            headers={"Content-Disposition": f"attachment; filename={file_name}"}
        )
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))