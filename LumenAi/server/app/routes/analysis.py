import os
import json
import shutil
import tempfile
import re
import asyncio
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks
from app.database import supabase
from app.engine.analyzer import LectureAnalyzer, RateLimitError
from app.engine.local_analyzer import LocalAnalyzer

router = APIRouter()

# Lazy-initialized analyzers — prevents startup crash if Gemini key or Ollama missing
_analyzer = None
_local_analyzer = None

def get_analyzer():
    global _analyzer
    if _analyzer is None:
        _analyzer = LectureAnalyzer()
    return _analyzer

def get_local_analyzer():
    global _local_analyzer
    if _local_analyzer is None:
        _local_analyzer = LocalAnalyzer()
    return _local_analyzer

# Semaphore to cap concurrent AI analyses (prevents Gemini quota exhaustion)
analysis_semaphore = asyncio.Semaphore(2)


def extract_json(text: str) -> str:
    """Extract JSON object using brace matching — handles markdown fences, preamble, etc."""
    fence_start = re.search(r"```(?:json)?\s*\n?", text)
    if fence_start:
        text = text[fence_start.end():]
        fence_end = text.rfind("```")
        if fence_end > 0:
            text = text[:fence_end]
    start = text.find('{')
    if start == -1:
        return text
    depth = 0
    in_string = False
    escape_next = False
    for i, ch in enumerate(text[start:], start=start):
        if escape_next:
            escape_next = False
            continue
        if ch == '\\' and in_string:
            escape_next = True
            continue
        if ch == '"' and not escape_next:
            in_string = not in_string
        if not in_string:
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    return text[start:i+1]
    return text[start:]


def extract_json_array(text: str) -> str:
    """Extract JSON array using brace matching."""
    fence_start = re.search(r"```(?:json)?\s*\n?", text)
    if fence_start:
        text = text[fence_start.end():]
        fence_end = text.rfind("```")
        if fence_end > 0:
            text = text[:fence_end]
    start = text.find('[')
    if start == -1:
        return text
    depth = 0
    in_string = False
    escape_next = False
    for i, ch in enumerate(text[start:], start=start):
        if escape_next:
            escape_next = False
            continue
        if ch == '\\' and in_string:
            escape_next = True
            continue
        if ch == '"' and not escape_next:
            in_string = not in_string
        if not in_string:
            if ch == '[':
                depth += 1
            elif ch == ']':
                depth -= 1
                if depth == 0:
                    return text[start:i+1]
    return text[start:]


# --- Background Tasks ---

async def save_quiz_background(engine, contents, user_id, lecture_id):
    """
    Background Task: 
    1. Awaits MCQ generation from Local or Gemini Engine.
    2. Parses strict JSON.
    3. Persists to Supabase in the background without blocking the user.
    """
    print(f"  ⏳ Background Task (Quiz): Generating for {lecture_id}...")
    try:
        # Retry logic: Try twice in case the LLM messes up the JSON.
        result_str = None
        for attempt in range(2):
            try:
                result_str = await engine.generate_quiz(contents)
                clean_json = extract_json_array(result_str)
                quizzes = json.loads(clean_json)
                
                # Handle case where LLM returns a dictionary instead of a strict array
                if isinstance(quizzes, dict):
                    if "quiz_questions" in quizzes:
                        quizzes = quizzes["quiz_questions"]
                    elif "quizzes" in quizzes:
                        quizzes = quizzes["quizzes"]
                    else:
                        for v in quizzes.values():
                            if isinstance(v, list):
                                quizzes = v
                                break
                        else:
                            quizzes = []
                
                break # Success!
            except Exception as e:
                print(f"  ⚠️ Background Task (Quiz) Attempt {attempt+1} failed: {e}")
                if attempt == 1:
                    raise e
        
        db_quizzes = []
        for q in quizzes:
            db_quizzes.append({
                "user_id": user_id,
                "lecture_id": lecture_id,
                "question": q.get("question"),
                "options": q.get("options", []),
                "correct_answer": q.get("correct_answer"),
                "explanation": q.get("explanation")
            })
        if db_quizzes:
            supabase.table("quiz_questions").insert(db_quizzes).execute()
        print(f"  ✅ Background Task (Quiz): Saved {len(db_quizzes)} MCQs!")
        
    except Exception as e:
        print(f"  ❌ Background Task (Quiz) Fatal Error: {e}")


async def save_flashcards_background(engine, contents, user_id, lecture_id):
    """
    Background Task: 
    1. Awaits Flashcard generation from Local or Gemini engine.
    2. Parses strict JSON.
    3. Persists to Supabase in the background.
    """
    print(f"  ⏳ Background Task (Flashcards): Generating for {lecture_id}...")
    try:
        result_str = None
        for attempt in range(2):
            try:
                result_str = await engine.generate_flashcards(contents)
                clean_json = extract_json_array(result_str)
                flashcards = json.loads(clean_json)
                
                # Handle case where LLM returns a dictionary instead of a strict array
                if isinstance(flashcards, dict):
                    if "flashcards" in flashcards:
                        flashcards = flashcards["flashcards"]
                    else:
                        for v in flashcards.values():
                            if isinstance(v, list):
                                flashcards = v
                                break
                        else:
                            flashcards = []
                
                break # Success!
            except Exception as e:
                print(f"  ⚠️ Background Task (Flashcards) Attempt {attempt+1} failed: {e}")
                if attempt == 1:
                    raise e
        
        db_fc = []
        for f in flashcards:
            db_fc.append({
                "user_id": user_id,
                "lecture_id": lecture_id,
                "front": f.get("front"),
                "back": f.get("back")
            })
        if db_fc:
            supabase.table("flashcards").insert(db_fc).execute()
        print(f"  ✅ Background Task (Flashcards): Saved {len(db_fc)} items!")
        
    except Exception as e:
        print(f"  ❌ Background Task (Flashcards) Fatal Error: {e}")


@router.post("/process")
async def process_lecture(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    subject_id: str = Form(...),
    unit_id: str = Form(None),
    user_id: str = Form(...),
    title: str = Form(None)
):
    """
    Main Lecture Analysis Endpoint (SMART CHAINING)
    1. Fast Sync Step: Extracts text, writes the Initial View (Summary).
    2. Async Step: Dispatches Quiz and Flashcards to Background.
    3. Fast Return: UI renders immediately.
    """
    print(f"🚀 Processing Lecture: {file.filename} (Unit: {unit_id})")

    # 1. Save Audio Temporarily
    suffix = os.path.splitext(file.filename)[1]
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name

    try:
        # 2. Fetch Syllabus Context (Grounding)
        syllabus_context = ""
        if unit_id:
            response = supabase.table("syllabus_sources")\
                .select("extracted_text")\
                .eq("unit_id", unit_id)\
                .execute()
            for row in response.data:
                if row.get("extracted_text"):
                    syllabus_context += row["extracted_text"] + "\n\n"
            print(f"  📚 Found Syllabus Context: {len(syllabus_context)} chars")

        # 3. Analyze — INITIAL VIEW (Synchronous)
        engine_used = "gemini"
        result_json_str = None
        contents = None

        try:
            print("  🌐 Trying Gemini API first...")
            engine_used = "gemini"
            engine = get_analyzer()
            async with analysis_semaphore:
                contents = await engine.prepare_content([tmp_path], syllabus_context)
                result_json_str = await engine.generate_initial_view(contents)
        except Exception as e:
            print(f"  ⚠️ Gemini failed ({e}). Falling back to Local LLM (Ollama)...")
            engine_used = "local_ollama"
            engine = get_local_analyzer()
            async with analysis_semaphore:
                contents = await engine.prepare_content([tmp_path], syllabus_context)
                result_json_str = await engine.generate_initial_view(contents)

        if not result_json_str:
            raise HTTPException(status_code=500, detail="The AI model returned no response. Please try again.")

        try:
            clean_json = extract_json(result_json_str)
            data = json.loads(clean_json)
            
            # Robustness: if LLM returned a quoted string instead of an object
            if isinstance(data, str):
                print("  ⚠️ LLM returned a JSON string instead of an object. Wrapping it.")
                data = {"summary": data}
            elif not isinstance(data, dict):
                data = {}
                
        except json.JSONDecodeError as e:
            print(f"❌ JSON Decode Error on Initial View: {e}")
            raise e

        # 4. Save Base Data immediately to DB
        lecture_data = {
            "user_id": user_id,
            "subject_id": subject_id,
            "unit_id": unit_id,
            "title": title or file.filename,
            "summary": data.get("summary", ""),
            "transcript": data.get("transcript", ""),
            "raw_analysis": data # Fast backup of mindmap, etc
        }
        res = supabase.table("lectures").insert(lecture_data).execute()
        lecture_id = res.data[0]['id']
        print(f"  ✅ Initial Lecture Created: {lecture_id}")

        # Synchronously insert ultra-light artifacts
        if data.get("mind_map"):
            mm = data["mind_map"]
            supabase.table("mind_maps").insert({
                "user_id": user_id,
                "lecture_id": lecture_id,
                "nodes": mm.get("nodes", []),
                "edges": mm.get("edges", [])
            }).execute()

        if data.get("code_snippets"):
            snippets = []
            for c in data["code_snippets"]:
                snippets.append({
                    "user_id": user_id,
                    "lecture_id": lecture_id,
                    "title": c.get("title"),
                    "language": c.get("language"),
                    "code_content": c.get("code_content")
                })
            supabase.table("code_snippets").insert(snippets).execute()

        if data.get("extracted_tasks"):
            tasks = []
            for t in data["extracted_tasks"]:
                tasks.append({
                    "user_id": user_id,
                    "lecture_id": lecture_id,
                    "title": t.get("title"),
                    "due_date": t.get("due_date") 
                })
            supabase.table("extracted_tasks").insert(tasks).execute()


        # 5. DISPATCH BACKGROUND TASKS
        # Now pass the same "engine" and parsed "contents" context to save time in the background
        background_tasks.add_task(save_quiz_background, engine, contents, user_id, lecture_id)
        background_tasks.add_task(save_flashcards_background, engine, contents, user_id, lecture_id)


        # RETURN INSTANTLY
        return {
            "status": "success", 
            "lecture_id": lecture_id,
            "engine_used": engine_used,
            "summary_preview": data.get("summary", "")[:100] + "..."
        }

    except json.JSONDecodeError as jde:
        short = result_json_str[:300] if result_json_str else 'EMPTY'
        raise HTTPException(status_code=500, detail=f"AI Model returned invalid JSON: {jde}. Output start: {short[:100]}")

    except Exception as e:
        error_msg = str(e)
        if "429" in error_msg:
            raise HTTPException(status_code=429, detail="Gemini API Quota Exceeded. Please try again in a minute.")
        raise HTTPException(status_code=500, detail=error_msg)
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except:
                pass


@router.post("/analyze_lecture/{lecture_id}")
async def analyze_lecture_on_demand(lecture_id: str, background_tasks: BackgroundTasks):
    """
    On-demand AI analysis for a previously pulled (un-analyzed) lecture.
    Triggered by the 'Make it Smart' button in the Flutter UI.
    """
    import io
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaIoBaseDownload
    from app.tasks.classroom_sync import get_valid_credentials
    
    # 1. Get the lecture row
    lecture_res = supabase.table("lectures").select("*").eq("id", lecture_id).execute()
    if not lecture_res.data:
        raise HTTPException(status_code=404, detail="Lecture not found.")
    
    lecture = lecture_res.data[0]
    drive_file_id = lecture.get("drive_file_id")
    user_id = lecture["user_id"]
    file_title = lecture["title"]
    
    if lecture.get("is_analyzed"):
        return {"status": "already_analyzed", "message": "This lecture has already been analyzed."}
    
    if not drive_file_id:
        raise HTTPException(status_code=400, detail="No Google Drive file ID stored. This lecture cannot be analyzed from Classroom.")
    
    # 2. Get user's Google tokens and build credentials with auto-refresh
    token_res = supabase.table("user_integrations").select("google_tokens").eq("user_id", user_id).execute()
    if not token_res.data or not token_res.data[0].get("google_tokens"):
        raise HTTPException(status_code=400, detail="Google Classroom not connected. Please reconnect.")
    
    tokens = token_res.data[0]["google_tokens"]
    creds = get_valid_credentials(tokens, user_id=user_id)
    drive_service = build('drive', 'v3', credentials=creds)
    
    # 3. Re-download the file from Google Drive
    print(f"🧠 Make it Smart: Re-downloading '{file_title}' from Drive...")
    try:
        request = drive_service.files().get_media(fileId=drive_file_id)
        fh = io.BytesIO()
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
    except Exception:
        try:
            request = drive_service.files().export_media(fileId=drive_file_id, mimeType='application/pdf')
            fh = io.BytesIO()
            downloader = MediaIoBaseDownload(fh, request)
            done = False
            while not done:
                status, done = downloader.next_chunk()
        except Exception as ex:
            raise HTTPException(status_code=500, detail=f"Failed to download file from Drive: {ex}")
    
    fh.seek(0)
    suffix = os.path.splitext(file_title)[1]
    if not suffix:
        suffix = '.pdf'
    
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(fh.read())
            tmp_path = tmp.name
        
        # 4. Run AI pipeline (with semaphore to limit concurrency)
        print(f"🧠 Running AI analysis on '{file_title}'...")
        engine = get_analyzer()
        try:
            async with analysis_semaphore:
                contents = await engine.prepare_content([tmp_path], "")
                result_json_str = await engine.generate_initial_view(contents)
        except Exception as e:
            print(f"⚠️ Gemini failed ({e}). Falling back to Ollama...")
            engine = get_local_analyzer()
            async with analysis_semaphore:
                contents = await engine.prepare_content([tmp_path], "")
                result_json_str = await engine.generate_initial_view(contents)
        
        if not result_json_str:
            raise Exception("No AI content generated.")
        
        clean_json = extract_json(result_json_str)
        data = json.loads(clean_json)
        
        if isinstance(data, str):
            data = {"summary": data}
        elif not isinstance(data, dict):
            data = {}
        
        # 5. Update the lecture row with analysis results
        supabase.table("lectures").update({
            "summary": data.get("summary", ""),
            "transcript": data.get("transcript", ""),
            "raw_analysis": data,
            "is_analyzed": True,
        }).eq("id", lecture_id).execute()
        
        print(f"✅ Lecture '{file_title}' is now SMART!")
        
        # 6. Save mind map if present
        if data.get("mind_map"):
            supabase.table("mind_maps").insert({
                "user_id": user_id, "lecture_id": lecture_id,
                "nodes": data["mind_map"].get("nodes", []),
                "edges": data["mind_map"].get("edges", [])
            }).execute()
        
        # 7. Fire quiz + flashcard generation in background
        background_tasks.add_task(save_quiz_background, engine, contents, user_id, lecture_id)
        background_tasks.add_task(save_flashcards_background, engine, contents, user_id, lecture_id)
        
        return {"status": "success", "message": f"'{file_title}' has been analyzed!", "data": data}
    
    except Exception as e:
        print(f"❌ Error analyzing lecture: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except:
                pass


@router.delete("/lecture/{lecture_id}")
async def delete_lecture(lecture_id: str):
    """Delete a lecture and its cascades."""
    try:
        supabase.table("lectures").delete().eq("id", lecture_id).execute()
        return {"status": "success", "message": "Lecture deleted successfully."}
    except Exception as e:
        print(f"❌ Error deleting lecture: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/lecture/{lecture_id}")
async def rename_lecture(lecture_id: str, new_title: str = Form(...)):
    """Rename a lecture."""
    try:
        response = supabase.table("lectures").update({"title": new_title}).eq("id", lecture_id).execute()
        if not response.data:
             raise Exception("Lecture not found")
             
        return {"status": "success", "message": "Lecture renamed successfully."}
    except Exception as e:
        print(f"❌ Error renaming lecture: {e}")
        raise HTTPException(status_code=500, detail=str(e))

