import ollama

print("Testing Ollama JSON output...")
r = ollama.chat(
    model="llama3.2",
    messages=[{
        "role": "user",
        "content": 'Reply with ONLY this exact JSON object, nothing else before or after it:\n{"summary": "test", "topics": ["a"], "flashcards": [], "quiz_questions": [], "mind_map": {"nodes": [], "edges": []}, "code_snippets": [], "extracted_tasks": [], "teacher_questions": [], "important_dates": [], "transcript": "test"}'
    }],
    options={"temperature": 0.1}
)
content = r["message"]["content"]
print(f"=== RAW OUTPUT ({len(content)} chars) ===")
print(repr(content[:1000]))
print(f"\n=== FIRST 500 CHARS DISPLAY ===")
print(content[:500])

import json, re
start = content.find('{')
print(f"\nFirst {{ at index: {start}")
if start >= 0:
    try:
        parsed = json.loads(content[start:])
        print("✅ JSON parsed successfully!")
        print(f"Keys: {list(parsed.keys())}")
    except json.JSONDecodeError as e:
        print(f"❌ JSON parse failed: {e}")
