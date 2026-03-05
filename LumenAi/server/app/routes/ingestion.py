import os
import shutil
import tempfile
import logging
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from markitdown import MarkItDown
from app.database import supabase
from app.middleware.auth import get_current_user

logger = logging.getLogger(__name__)

# Allowed file extensions and max size
ALLOWED_DOC_EXTENSIONS = {'.pdf', '.docx', '.pptx', '.doc', '.txt', '.md'}
MAX_DOC_SIZE_MB = 20
import pytesseract
import fitz  # PyMuPDF
from PIL import Image
import io
import os

if os.name == 'nt':
    tesseract_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.path.exists(tesseract_path):
        pytesseract.pytesseract.tesseract_cmd = tesseract_path

router = APIRouter()
md = MarkItDown()

@router.post("/upload")
async def upload_syllabus(
    file: UploadFile = File(...),
    subject_id: str = Form(...),
    unit_id: str = Form(None),
    title: str = Form(None),
    user_id: str = Depends(get_current_user),
):
    """
    Uploads a syllabus/document (PDF, DOCX, PPTX), extracts text, and stores it.
    """
    
    logger.info(f"📥 Receiving upload: {file.filename} for Unit: {unit_id or 'General'}")

    # 0. Validate file extension and size
    suffix = os.path.splitext(file.filename or '')[1].lower()
    if suffix not in ALLOWED_DOC_EXTENSIONS:
        raise HTTPException(status_code=400, detail=f"File type '{suffix}' not allowed. Allowed: {', '.join(ALLOWED_DOC_EXTENSIONS)}")

    # Check file size (read content to get actual size)
    contents = await file.read()
    if len(contents) > MAX_DOC_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"File too large. Maximum size: {MAX_DOC_SIZE_MB}MB")
    await file.seek(0)  # Reset for downstream reading

    # 1. Save uploaded file temporarily for MarkItDown to process
    # (suffix already computed above in validation block)
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name
    
    try:
        # 2. Extract Text using MarkItDown
        result = md.convert(tmp_path)
        extracted_text = result.text_content
        
        # 2b. OCR Fallback for Scanned PDFs
        # If MarkItDown returns very short or gibberish text on a PDF, it's likely a scan.
        # We trigger pytesseract to read the images.
        if suffix.lower() == '.pdf':
            # Basic heuristic: if the extracted text has fewer than 20 distinct dictionary-like words, or is very short
            words = [w for w in extracted_text.split() if w.isalpha() and len(w) > 2]
            if len(words) < 20:
                print("⚠️ MarkItDown found very little text. Attempting OCR fallback for scanned PDF...")
                try:
                    with fitz.open(tmp_path) as doc:
                        ocr_text = ""
                        for page_num in range(len(doc)):
                            page = doc.load_page(page_num)
                            pix = page.get_pixmap(dpi=150)
                            img_bytes = pix.tobytes("jpeg")
                            with Image.open(io.BytesIO(img_bytes)) as img:
                                ocr_text += pytesseract.image_to_string(img) + "\n\n"
                    
                    if len(ocr_text.strip()) > len(extracted_text.strip()):
                        print("✅ OCR Success! Replaced gibberish with real text.")
                        extracted_text = ocr_text
                except Exception as ocr_e:
                    print(f"⚠️ OCR Failed (Is Tesseract installed on the system?): {ocr_e}")
        
        # 3. Upload Original File to Supabase Storage (Optional backup)
        # Note: You need to create a bucket named 'syllabus_docs' in Supabase first
        path_unit = unit_id if unit_id else "general"
        file_path = f"{user_id}/{path_unit}/{file.filename}"
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
            "subject_id": subject_id,
            "title": title or file.filename,
            "file_path": file_path,
            "extracted_text": extracted_text,
            "metadata": {"source": "upload_api"}
        }
        if unit_id:
            data["unit_id"] = unit_id
        
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
            try:
                os.remove(tmp_path)
            except:
                pass

@router.delete("/syllabus/{syllabus_id}")
async def delete_syllabus(syllabus_id: str, user_id: str = Depends(get_current_user)):
    """Delete a syllabus from the database and storage."""
    try:
        # 1. Fetch file_path from DB
        response = supabase.table("syllabus_sources").select("file_path").eq("id", syllabus_id).single().execute()
        file_path = response.data.get("file_path")
        
        # 2. Delete from Supabase Storage (if it was uploaded)
        if file_path and file_path != "local_only":
            supabase.storage.from_("syllabus_docs").remove([file_path])
            
        # 3. Delete from Database
        supabase.table("syllabus_sources").delete().eq("id", syllabus_id).execute()
        
        return {"status": "success", "message": "Syllabus deleted successfully."}
    except Exception as e:
        print(f"❌ Error deleting syllabus: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/syllabus/{syllabus_id}")
async def rename_syllabus(syllabus_id: str, new_title: str = Form(...), user_id: str = Depends(get_current_user)):
    """Rename a syllabus."""
    try:
        response = supabase.table("syllabus_sources").update({"title": new_title}).eq("id", syllabus_id).execute()
        if not response.data:
             raise Exception("Syllabus not found")
             
        return {"status": "success", "message": "Syllabus renamed successfully."}
    except Exception as e:
        print(f"❌ Error renaming syllabus: {e}")
        raise HTTPException(status_code=500, detail=str(e))
