"""
Real AI Chat endpoint — sends user question to Gemini/Ollama and returns answer.
Supports multi-turn conversation through the 'context' field.
"""
import os
import logging
from fastapi import APIRouter, Form, Depends
from fastapi.responses import JSONResponse
from app.database import supabase
from app.middleware.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/ask")
async def ask_ai(
    question: str = Form(...),
    context: str = Form(""),
    subject_id: str = Form(None),
    unit_id: str = Form(None),
    user_id: str = Depends(get_current_user),
):
    system_prompt = (
        "You are Lumen AI, a friendly and knowledgeable study assistant. "
        "Help students understand academic concepts clearly and concisely. "
        "When given lecture context or syllabus, use it to give more specific, grounded answers.\n\n"
        "IMPORTANT: At the end of your response, always suggest exactly 3 follow-up questions "
        "the student might want to ask next. Format them on separate lines prefixed with 'SUGGESTION:' "
        "Example:\nSUGGESTION: Can you explain this concept with an example?\n"
        "SUGGESTION: How does this relate to the previous topic?\n"
        "SUGGESTION: What are common exam questions on this?"
    )
    
    # Build RAG context from database
    db_context = ""
    if user_id:
        try:
            # Fetch recent syllabus sources
            syllabus_query = supabase.table("syllabus_sources").select("title, extracted_text").eq("user_id", user_id)
            if subject_id:
                syllabus_query = syllabus_query.eq("subject_id", subject_id)
            if unit_id:
                syllabus_query = syllabus_query.eq("unit_id", unit_id)
                
            syllabus_res = syllabus_query.order("created_at", desc=True).limit(3).execute()
            
            if syllabus_res.data:
                db_context += "--- RECENT SYLLABUS DOCS ---\n"
                for item in syllabus_res.data:
                    content = str(item.get('extracted_text', ''))[:1500]
                    db_context += f"Syllabus: {item.get('title')}\nContent: {content}\n\n"
            
            # Fetch recent lectures
            query = supabase.table("lectures").select("title, summary").eq("user_id", user_id)
            if subject_id:
                query = query.eq("subject_id", subject_id)
            if unit_id:
                query = query.eq("unit_id", unit_id)
                
            lectures_res = query.order("created_at", desc=True).limit(5).execute()
            
            if lectures_res.data:
                db_context += "--- RECENT LECTURE SUMMARIES ---\n"
                for item in lectures_res.data:
                    db_context += f"Lecture: {item.get('title')}\nSummary: {item.get('summary')}\n\n"
                    
        except Exception as e:
            logger.warning(f"Failed to fetch DB context for chat: {e}")

    # Build the full message with conversation history
    parts = []
    if context:
        parts.append(f"[Conversation History]:\n{context}")
    if db_context:
        parts.append(f"[Study Materials]:\n{db_context}")
    parts.append(f"Question: {question}")
    
    user_message = "\n\n".join(parts)

    try:
        # 1. Try Gemini API first
        try:
            from google import genai
            from app.config import Config
            client = genai.Client(api_key=Config.GEMINI_API_KEY)
            full_prompt = f"{system_prompt}\n\n{user_message}"
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[full_prompt],
            )
            raw_answer = response.text
        except Exception as e:
            # 2. Fallback to Ollama if Gemini API fails
            logger.warning(f"Chat Gemini failed ({e}). Falling back to Ollama...")
            import ollama
            response = ollama.chat(
                model=os.getenv("OLLAMA_MODEL", "llama3.2"),
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                options={"temperature": 0.7, "num_predict": 1024},
            )
            raw_answer = response["message"]["content"]

        # Parse suggestions from the response
        answer_lines = raw_answer.strip().split('\n')
        suggestions = []
        answer_parts = []
        
        for line in answer_lines:
            stripped = line.strip()
            if stripped.startswith("SUGGESTION:"):
                suggestion = stripped[len("SUGGESTION:"):].strip()
                if suggestion:
                    suggestions.append(suggestion)
            else:
                answer_parts.append(line)
        
        # Clean up the answer (remove trailing empty lines)
        answer = '\n'.join(answer_parts).strip()

        return JSONResponse({
            "answer": answer, 
            "suggestions": suggestions[:3]  # Max 3 suggestions
        })

    except Exception as e:
        logger.error(f"Chat error: {e}")
        return JSONResponse(
            {"answer": f"Sorry, I couldn't process that right now. ({e})", "suggestions": []},
            status_code=200,
        )
