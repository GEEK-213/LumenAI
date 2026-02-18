import os
import json
import shutil
import tempfile
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from app.database import supabase
from app.engine.analyzer import LectureAnalyzer

router = APIRouter()
analyzer = LectureAnalyzer()

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

        # 3. Analyze with Gemini
        result_json_str = await analyzer.analyze_multimodal([tmp_path], syllabus_context)
        
        if not result_json_str:
            raise HTTPException(status_code=500, detail="Gemini returned no response.")

        # Clean Markdown formatting if present
        clean_json = result_json_str.strip().replace("```json", "").replace("```", "")
        data = json.loads(clean_json)

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
            "summary_preview": data.get("summary")[:100] + "..."
        }

    except json.JSONDecodeError:
        print("❌ Gemini extraction failed: Invalid JSON received")
        raise HTTPException(status_code=500, detail="AI Model failed to generate valid structured data.")
    except Exception as e:
        print(f"❌ Processing Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
