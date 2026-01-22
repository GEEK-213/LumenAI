import os
from supabase import create_client, Client

url: url = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_ANON_KEY")
supa: Client = create_client(url, key)