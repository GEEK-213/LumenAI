import requests
import os

# Updated to match the filename in your screenshot
file_name = "test_audio.mp3" 
file_path = os.path.join(os.getcwd(), file_name)

# Make sure this matches the route in your main.py
url = "http://127.0.0.1:8000/lecture/analyze"

def test_analyze():
    if not os.path.exists(file_path):
        print(f"❌ Error: {file_name} not found in {os.getcwd()}")
        return

    with open(file_path, "rb") as audio_file:
        # FastAPI expects the key to be 'file' based on your previous code
        files = {"file": (file_name, audio_file, "audio/mpeg")}
        print(f"🚀 Sending {file_name} to {url}...")
        
        try:
            response = requests.post(url, files=files)
            if response.status_code == 200:
                print("✅ Success!")
                # Pretty print the JSON result
                import json
                print(json.dumps(response.json(), indent=4))
            else:
                print(f"⚠️ Error {response.status_code}: {response.text}")
        except Exception as e:
            print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    test_analyze()