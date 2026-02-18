from supabase import create_client, Client
from app.config import Config

# Initialize Supabase Client
# This client will be used throughout the app to interact with the database/storage.
supabase: Client = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)
