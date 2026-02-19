import requests
import uuid
import json
import os # Imported globally to fix the UnboundLocalError

# Configuration
BASE_URL = "http://127.0.0.1:8001"

# ⚠️ REPLACE THIS WITH YOUR ACTUAL SUPABASE USER ID
# Go to Supabase -> Authentication -> Users -> Copy User UID
REAL_USER_ID = "450c4165-3f6d-4a06-8b63-cb62f02c252d" 

def test_upload():
    print("\n🚀 Testing Analysis Upload...")
    
    url = f"{BASE_URL}/analysis/process"
    
    # 1. Create a dummy file
    dummy_file = "test_lecture.txt"
    with open(dummy_file, "w") as f:
        f.write("This is a test lecture content for Lumen AI integration testing.")

    # 2. Prepare Data
    payload = {
        "user_id": REAL_USER_ID, # Sending the REAL ID now
        "unit_id": "",           # Optional, sending empty string is safe
        "title": "Backend Connectivity Test"
    }

    try:
        with open(dummy_file, 'rb') as f_obj:
            files = {
                'file': (dummy_file, f_obj, 'text/plain')
            }
            print(f"📡 Sending request to {url}...")
            response = requests.post(url, data=payload, files=files)
        
        if response.status_code == 200:
            print(f"✅ Analysis Success! Response:\n{json.dumps(response.json(), indent=2)}")
        else:
            print(f"❌ Analysis Failed: {response.status_code}")
            try:
                print(response.json())
            except:
                print(response.text)
            
    except Exception as e:
        print(f"❌ Connection Error: {e}")
    finally:
        # Cleanup: Remove the dummy file if it exists
        if os.path.exists(dummy_file):
            try:
                os.remove(dummy_file)
                print("🧹 Cleanup: Dummy file removed.")
            except Exception as e:
                print(f"⚠️ Could not remove dummy file: {e}")

def health_check():
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"Health Check: {response.status_code} - {response.json()}")
    except:
        print("❌ Server is offline")

if __name__ == "__main__":
    health_check()
    test_upload()