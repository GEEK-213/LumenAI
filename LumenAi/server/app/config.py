import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY") # Use ANON key for client-side/public, or SERVICE_ROLE for admin tasks if needed. 
    # STRICT RULE: We use ANON key for now, simulating user interactions via RLS.
    
    GEMINI_API_KEY = os.getenv("Gemini_API_key")
    
    # Validation
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("CRITICAL: SUPABASE_URL or SUPABASE_ANON_KEY is missing from .env")
