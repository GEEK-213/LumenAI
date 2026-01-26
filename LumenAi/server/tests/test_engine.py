import requests
import os
import json

# Define your file names
audio_file = "test_audio.mp3"
doc_file = "lecture_slides.pptx" # Or .pdf, .docx, .xlsx

url = "http://127.0.0.1:8000/lecture/analyze"

def test_multimodal():
    # Check if files exist
    if not os.path.exists(audio_file) or not os.path.exists(doc_file):
        print(f"❌ Error: Ensure {audio_file} and {doc_file} are in this folder.")
        return

    # Open both files
    with open(audio_file, "rb") as a_file, open(doc_file, "rb") as d_file:
        # FastAPI expects a LIST of files if you use List[UploadFile]
        # Or multiple keys if you named them specifically
        files = [
            ("files", (audio_file, a_file, "audio/mpeg")),
            ("files", (doc_file, d_file, "application/vnd.openxmlformats-officedocument.presentationml.presentation"))
        ]
        
        print(f"🚀 Sending multimodal data to {url}...")
        
        try:
            response = requests.post(url, files=files)
            if response.status_code == 200:
                print("✅ Success! AI has cross-referenced your files.")
                print(json.dumps(response.json(), indent=4))
            else:
                print(f"⚠️ Error {response.status_code}: {response.text}")
        except Exception as e:
            print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    test_multimodal()