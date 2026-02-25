import os
import asyncio
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

supabase: Client = create_client(url, key)

async def main():
    try:
        # We need to alter the table. Since we are using the Supabase client, we might not have direct SQL access through the Python client easily for DDL.
        # But we can try using RPC if a generic one exists, or we might need to instruct the user.
        print("Please run this in your Supabase SQL Editor:")
        print("ALTER TABLE public.syllabus_sources ALTER COLUMN unit_id DROP NOT NULL;")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
