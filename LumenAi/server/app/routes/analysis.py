import os
import json
import shutil
import tempfile
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.database import supabase
from app.engine.analyzer import LectureAnalyzer, RateLimitError
from app.engine.local_analyzer import LocalAnalyzer

router = APIRouter()
analyzer = LectureAnalyzer()
local_analyzer = LocalAnalyzer()

@router.post("/process")
async def process_lecture(
    file: UploadFile = File(...),
    unit_id: str = Form(None),
    user_id: str = Form(...),
    title: str = Form(None)
):
    """
    Main Lecture Analysis Endpoint.
    1. Uploads Audio
    2. Fetches Syllabus Context (Grounding)
    3. Analyzes via Gemini
    4. Saves 5+ artifacts to DB
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
            
            # Concatenate all syllabus chunks (Naive Context Stuffing)
            # Todo: Replace with RAG Vector Search for large syllabi
            for row in response.data:
                if row.get("extracted_text"):
                    syllabus_context += row["extracted_text"] + "\n\n"
            
            print(f"  📚 Found Syllabus Context: {len(syllabus_context)} chars")

        # 3. Analyze — check if local-only mode is enabled
        engine_used = "gemini"
        result_json_str = None

        use_local = os.getenv("USE_LOCAL_LLM", "false").lower() == "true"

        if use_local:
            print("  🔧 USE_LOCAL_LLM=true — Skipping Gemini, using Ollama directly.")
            engine_used = "local_ollama"
            result_json_str = await local_analyzer.analyze([tmp_path], syllabus_context)
        else:
            try:
                result_json_str = await analyzer.analyze_multimodal([tmp_path], syllabus_context)
            except RateLimitError as rle:
                print(f"  ⚠️ Gemini unavailable: {rle}")
                print("  🔄 Falling back to Local LLM (Ollama)...")
                engine_used = "local_ollama"
                result_json_str = await local_analyzer.analyze([tmp_path], syllabus_context)

        if not result_json_str:
            raise HTTPException(status_code=500, detail="Both Gemini and Local LLM returned no response.")


        # Clean and extract JSON from model response
        import re

        def extract_json(text: str) -> str:
            """Extract JSON object using brace matching — handles markdown fences, preamble, etc."""
            # First try: strip markdown code fences (use brace matcher on content inside fence)
            fence_start = re.search(r"```(?:json)?\s*\n?", text)
            if fence_start:
                text = text[fence_start.end():]  # Strip the opening fence
                fence_end = text.rfind("```")
                if fence_end > 0:
                    text = text[:fence_end]  # Strip the closing fence
            # Find first { and match to its closing } using depth counting
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
            return text[start:]  # Return from first { to end if no balanced close found

        try:
            clean_json = extract_json(result_json_str)
            data = json.loads(clean_json)
        except json.JSONDecodeError as e:
            print(f"❌ JSON Decode Error: {e}")
            print(f"📉 Raw Model Output (first 2000 chars):\n{result_json_str[:2000]}\n")
            raise e


        # 4. Save to Database (The Graph Logic)
        
        # A. Create Lecture Record
        lecture_data = {
            "user_id": user_id,
            "unit_id": unit_id,
            "title": title or file.filename,
            "summary": data.get("summary", ""),
            "transcript": data.get("transcript", ""),
            "raw_analysis": data # Backup
        }
        res = supabase.table("lectures").insert(lecture_data).execute()
        lecture_id = res.data[0]['id']
        print(f"  ✅ Lecture Created: {lecture_id}")

        # B. Bulk Insert Artifacts
        
        # Flashcards
        if data.get("flashcards"):
            flashcards = []
            for f in data["flashcards"]:
                flashcards.append({
                    "user_id": user_id,
                    "lecture_id": lecture_id,
                    "front": f.get("front"),
                    "back": f.get("back")
                })
            supabase.table("flashcards").insert(flashcards).execute()

        # Quiz Questions
        if data.get("quiz_questions"):
            quizzes = []
            for q in data["quiz_questions"]:
                quizzes.append({
                    "user_id": user_id,
                    "lecture_id": lecture_id,
                    "question": q.get("question"),
                    "options": q.get("options", []),
                    "correct_answer": q.get("correct_answer"),
                    "explanation": q.get("explanation")
                })
            supabase.table("quiz_questions").insert(quizzes).execute()

        # Mind Map
        if data.get("mind_map"):
            mm = data["mind_map"]
            supabase.table("mind_maps").insert({
                "user_id": user_id,
                "lecture_id": lecture_id,
                "nodes": mm.get("nodes", []),
                "edges": mm.get("edges", [])
            }).execute()

        # Code Snippets
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

        # Tasks
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

        return {
            "status": "success", 
            "lecture_id": lecture_id,
            "engine_used": engine_used,
            "summary_preview": data.get("summary", "")[:100] + "..."
        }

    except json.JSONDecodeError as jde:
        short = result_json_str[:300] if result_json_str else 'EMPTY'
        print(f"❌ JSON Decode Error: {jde}")
        print(f"📉 Raw output snippet: {short}")
        raise HTTPException(status_code=500, detail=f"AI Model returned invalid JSON: {jde}. Output start: {short[:100]}")

    except Exception as e:
        error_msg = str(e)
        print(f"❌ Processing Error: {error_msg}")
        if "429" in error_msg:
            raise HTTPException(status_code=429, detail="Gemini API Quota Exceeded. Please try again in a minute.")
        raise HTTPException(status_code=500, detail=error_msg)
    finally:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except:
                pass
