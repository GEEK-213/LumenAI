import sys, os, httpx
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.database import supabase

url = f"{supabase.supabase_url}/rest/v1/"
headers = {
    "apikey": supabase.supabase_key,
    "Authorization": f"Bearer {supabase.supabase_key}"
}
r = httpx.get(url, headers=headers)
schema = r.json()
if 'definitions' in schema and 'extracted_tasks' in schema['definitions']:
    print(list(schema['definitions']['extracted_tasks']['properties'].keys()))
else:
    print("extracted_tasks not found in definitions")
