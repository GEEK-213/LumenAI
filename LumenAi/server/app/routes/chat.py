"""
Real AI Chat endpoint — sends user question to Gemini/Ollama and returns answer.
"""
import os
from fastapi import APIRouter, Form
from fastapi.responses import JSONResponse

router = APIRouter()

USE_LOCAL_LLM = os.getenv("USE_LOCAL_LLM", "false").lower() == "true"

@router.post("/ask")
async def ask_ai(
    question: str = Form(...),
    context: str = Form(""),
):
    """Simple study assistant chat — no RAG needed for MVP."""
    system_prompt = (
        "You are Lumen AI, a friendly and knowledgeable study assistant. "
        "Help students understand academic concepts clearly and concisely. "
        "When given lecture context, use it to give more specific answers."
    )
    user_message = question
    if context:
        user_message = f"[Lecture Context]: {context[:2000]}\n\nQuestion: {question}"

    try:
        if USE_LOCAL_LLM:
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
        else:
            from google import genai
            api_key = os.getenv("GEMINI_API_KEY")
            client = genai.Client(api_key=api_key)
            full_prompt = f"{system_prompt}\n\n{user_message}"
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[full_prompt],
            )
            answer = response.text

        return JSONResponse({"answer": answer})

    except Exception as e:
        print(f"❌ Chat error: {e}")
        return JSONResponse(
            {"answer": f"Sorry, I couldn't process that right now. ({e})"},
            status_code=200,  # Return 200 so Flutter shows the error gracefully
        )
