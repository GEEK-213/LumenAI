import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    # Prefer SERVICE_ROLE key for backend admin tasks; fall back to ANON if not set (but writes may fail due to RLS).
    SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
    
    GEMINI_API_KEY = os.getenv("Gemini_API_key")
    
    # Validation
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("CRITICAL: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY (or ANON_KEY) is missing from .env")
