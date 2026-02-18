import os
import shutil
import tempfile
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from markitdown import MarkItDown
from app.database import supabase

router = APIRouter()
md = MarkItDown()

@router.post("/upload")
async def upload_syllabus(
    file: UploadFile = File(...),
    unit_id: str = Form(...),
    user_id: str = Form(...), # TODO: Extract from JWT in production
    title: str = Form(None)
):
    """
    Uploads a syllabus/document (PDF, DOCX, PPTX), extracts text, and stores it.
    """
    
    print(f"📥 Receiving upload: {file.filename} for Unit: {unit_id}")
    
    # 1. Save uploaded file temporarily for MarkItDown to process
    suffix = os.path.splitext(file.filename)[1]
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name
    
    try:
        # 2. Extract Text using MarkItDown
        result = md.convert(tmp_path)
        extracted_text = result.text_content
        
        # 3. Upload Original File to Supabase Storage (Optional backup)
        # Note: You need to create a bucket named 'syllabus_docs' in Supabase first
        file_path = f"{user_id}/{unit_id}/{file.filename}"
        try:
           with open(tmp_path, "rb") as f:
               supabase.storage.from_("syllabus_docs").upload(
                   file_path, 
                   f, 
                   file_options={"upsert": "true"}
               )
        except Exception as e:
            print(f"⚠️ Storage upload failed (Bucket might not exist): {e}")
            # We continue because the database entry is more important for RAG
            file_path = "local_only"

        # 4. Insert into Knowledge Base (syllabus_sources)
        data = {
            "user_id": user_id,
            "unit_id": unit_id,
            "title": title or file.filename,
            "file_path": file_path,
            "extracted_text": extracted_text,
            "metadata": {"source": "upload_api"}
        }
        
        response = supabase.table("syllabus_sources").insert(data).execute()
        
        # 5. Trigger Async Job for Vectorization (Embeddings)
        # TODO: Call a background task here to chunk and embed 'extracted_text'
        
        return {"status": "success", "id": response.data[0]['id'], "message": "Syllabus processed and stored."}

    except Exception as e:
        print(f"❌ Error during ingestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Cleanup temp file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
