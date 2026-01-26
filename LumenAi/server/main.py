import os
import json
import asyncio
import re
from app.engine.analyzer import LectureAnalyzer
from dotenv import load_dotenv

load_dotenv()

ASSETS_DIR = "tests/assets"
RESULTS_DIR = "processed_results"
TRACKER_FILE = "processed_files.json"

os.makedirs(RESULTS_DIR, exist_ok=True)

def sanitize_filename(filename):
    # Removes emojis and special characters that cause ASCII errors
    return re.sub(r'[^\x00-\x7f]', r'', filename).strip()

def get_processed_list():
    if os.path.exists(TRACKER_FILE):
        with open(TRACKER_FILE, "r") as f:
            try: return json.load(f)
            except: return []
    return []

def save_processed_file(filename):
    processed = get_processed_list()
    if filename not in processed:
        processed.append(filename)
        with open(TRACKER_FILE, "w") as f:
            json.dump(processed, f, indent=4)

async def start_interactive_analysis():
    analyzer = LectureAnalyzer()
    
    # RENAME FILES WITH EMOJIS BEFORE LISTING
    for f in os.listdir(ASSETS_DIR):
        clean_name = sanitize_filename(f)
        if clean_name != f:
            os.rename(os.path.join(ASSETS_DIR, f), os.path.join(ASSETS_DIR, clean_name))

    processed = get_processed_list()
    valid_exts = ('.mp3', '.pdf', '.pptx', '.docx', '.xlsx', ".wav", ".mp4", ".mov")
    all_files = [f for f in os.listdir(ASSETS_DIR) if f.lower().endswith(valid_exts)]
    new_files = [f for f in all_files if f not in processed]

    if not new_files:
        print("\n✨ Assets already analyzed!")
        return

    print("\n--- LUMEN AI: Pending Files ---")
    for i, file in enumerate(new_files):
        print(f"[{i}] {file}")

    choice = input("\nEnter choice (number or 'all'): ")
    to_process = new_files if choice.lower() == 'all' else [new_files[int(x.strip())] for x in choice.split(",")]

    for file_name in to_process:
        print(f"\n🚀 Processing: {file_name}")
        file_path = os.path.join(ASSETS_DIR, file_name)
        
        try:
            result_raw = await analyzer.analyze_multimodal([file_path])
            if result_raw:
                result_data = json.loads(result_raw.strip().replace("```json", "").replace("```", ""))
                output_name = f"{os.path.splitext(file_name)[0]}_result.json"
                output_path = os.path.join(RESULTS_DIR, output_name)
                with open(output_path, "w") as f:
                    json.dump(result_data, f, indent=4)
                save_processed_file(file_name)
                print(f"✅ Success! Data saved to: {output_path}")
            else:
                print(f"❌ Failed to get response.")
        except Exception as e:
            print(f"❌ Fatal Error: {e}")

if __name__ == "__main__":
    asyncio.run(start_interactive_analysis())