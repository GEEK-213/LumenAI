import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    # Prefer SERVICE_ROLE key for backend admin tasks; fall back to ANON if not set (but writes may fail due to RLS).
    SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
    
    # --- Gemini API Key Rotation Engine ---
    # Accepts a comma-separated list of keys: GEMINI_KEYS="key1,key2,key3"
    # Falls back to the legacy single-key variable for backward compatibility.
    _raw_keys = os.getenv("GEMINI_KEYS", "")
    GEMINI_API_KEYS: list[str] = [k.strip() for k in _raw_keys.split(",") if k.strip()]
    
    # Backward compatibility: if GEMINI_KEYS is not set, use the single legacy key
    # Also handles comma-separated keys in the legacy variable
    if not GEMINI_API_KEYS:
        _single_key = os.getenv("Gemini_API_key", "")
        if _single_key:
            GEMINI_API_KEYS = [k.strip() for k in _single_key.split(",") if k.strip()]
    
    # Expose the first key as the default for any code that still uses the single-key path
    GEMINI_API_KEY = GEMINI_API_KEYS[0] if GEMINI_API_KEYS else None
    
    # Validation
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("CRITICAL: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY (or ANON_KEY) is missing from .env")
