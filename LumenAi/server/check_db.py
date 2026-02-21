"""Check what raw_analysis looks like in Supabase for the last processed lecture."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import supabase

# Get the latest lecture
res = supabase.table("lectures").select("id, title, summary, raw_analysis").order("created_at", desc=True).limit(1).execute()

if res.data:
    lecture = res.data[0]
    print(f"Lecture ID: {lecture['id']}")
    print(f"Title: {lecture['title']}")
    print(f"Summary (direct col): {str(lecture.get('summary', ''))[:200]}")
    
    raw = lecture.get('raw_analysis')
    if raw:
        print(f"\nraw_analysis type: {type(raw)}")
        if isinstance(raw, dict):
            print(f"raw_analysis keys: {list(raw.keys())}")
            print(f"summary: {str(raw.get('summary', 'MISSING'))[:200]}")
            print(f"topics: {raw.get('topics', 'MISSING')}")
            print(f"flashcards count: {len(raw.get('flashcards', []))}")
            print(f"quiz count: {len(raw.get('quiz_questions', []))}")
        else:
            print(f"raw_analysis value: {str(raw)[:500]}")
    else:
        print("raw_analysis is NULL!")
else:
    print("No lectures found in DB")
