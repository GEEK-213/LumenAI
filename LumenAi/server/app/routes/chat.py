"""
Real AI Chat endpoint — sends user question to Gemini/Ollama and returns answer.
"""
import os
from fastapi import APIRouter, Form
from fastapi.responses import JSONResponse
from app.database import supabase

router = APIRouter()


@router.post("/ask")
async def ask_ai(
    question: str = Form(...),
    context: str = Form(""),
    user_id: str = Form(None),
):
    system_prompt = (
        "You are Lumen AI, a friendly and knowledgeable study assistant. "
        "Help students understand academic concepts clearly and concisely. "
        "When given lecture context or syllabus, use it to give more specific, grounded answers."
    )
    
    db_context = ""
    if user_id:
        try:
            # Fetch recent syllabus sources
            syllabus_res = supabase.table("syllabus_sources").select("title, extracted_text").eq("user_id", user_id).order("created_at", desc=True).limit(3).execute()
            if syllabus_res.data:
                db_context += "--- RECENT SYLLABUS DOCS ---\n"
                for item in syllabus_res.data:
                    # Truncate content to avoid blowing up context window
                    content = str(item.get('extracted_text', ''))[:1500]
                    db_context += f"Syllabus: {item.get('title')}\nContent: {content}\n\n"
            
            # Fetch recent lectures
            lectures_res = supabase.table("lectures").select("title, summary").eq("user_id", user_id).order("created_at", desc=True).limit(3).execute()
            if lectures_res.data:
                db_context += "--- RECENT LECTURE SUMMARIES ---\n"
                for item in lectures_res.data:
                    db_context += f"Lecture: {item.get('title')}\nSummary: {item.get('summary')}\n\n"
                    
        except Exception as e:
            print(f"⚠️ Failed to fetch DB context for chat: {e}")

    combined_context = (context + "\n" + db_context).strip()
    user_message = question
    if combined_context:
        user_message = f"[Study Context]:\n{combined_context}\n\nQuestion: {question}"

    try:
        # 1. Try Gemini API first
        try:
            from google import genai
            api_key = os.getenv("GEMINI_API_KEY")
            client = genai.Client(api_key=api_key)
            full_prompt = f"{system_prompt}\n\n{user_message}"
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[full_prompt],
            )
            answer = response.text
        except Exception as e:
            # 2. Fallback to Ollama if Gemini API fails
            print(f"  ⚠️ Chat Gemini failed ({e}). Falling back to Local LLM (Ollama)...")
            import ollama
            response = ollama.chat(
                model=os.getenv("OLLAMA_MODEL", "llama3.2"),
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                options={"temperature": 0.7, "num_predict": 1024},
            )
            answer = response["message"]["content"]

        return JSONResponse({"answer": answer})

    except Exception as e:
        print(f"❌ Chat error: {e}")
        return JSONResponse(
            {"answer": f"Sorry, I couldn't process that right now. ({e})"},
            status_code=200,  # Return 200 so Flutter shows the error gracefully
        )
