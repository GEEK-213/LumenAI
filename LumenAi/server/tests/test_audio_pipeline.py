"""
LumenAI -- Audio Processing Integration Test
Tests the FULL pipeline: Upload -> Transcribe -> AI Analyze -> JSON Parse -> Return

PREREQUISITES:
- Server must be running: cd server && uvicorn main:app --port 8001
- GEMINI_API_KEY must be set in .env
- Supabase must be configured

USAGE:
  python tests/test_audio_pipeline.py              # Uses a simple text file
  python tests/test_audio_pipeline.py audio.mp3     # Uses a real audio file
"""
import os
import sys
import json
import time
import tempfile
import uuid
import requests

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

BASE_URL = os.getenv("LUMEN_TEST_URL", "http://localhost:8001")

# Generate valid UUIDs for testing (Supabase requires UUID format)
TEST_USER_ID = str(uuid.uuid4())
TEST_SUBJECT_ID = str(uuid.uuid4())


# ---------------------------------------------------------------
# TEST HELPERS
# ---------------------------------------------------------------

def check_server():
    """Verify server is running."""
    try:
        r = requests.get(f"{BASE_URL}/docs", timeout=5)
        return r.status_code == 200
    except requests.ConnectionError:
        return False

def create_test_file(ext=".txt", content="This is a test lecture about machine learning. "
    "Neural networks are computational models inspired by the brain. "
    "Deep learning uses multiple layers to learn hierarchical features. "
    "Gradient descent is an optimization algorithm. "
    "Backpropagation computes gradients for each layer. "
    "Convolutional neural networks are used for image recognition. "
    "Recurrent neural networks handle sequential data. "
    "Transformers use self-attention mechanisms. "
    "Large language models like GPT are trained on vast text corpora. "
    "Reinforcement learning trains agents through rewards and penalties."):
    """Create a temp file for testing."""
    f = tempfile.NamedTemporaryFile(delete=False, suffix=ext, mode='w')
    f.write(content)
    f.close()
    return f.name


# ---------------------------------------------------------------
# TEST 1: Server Health Check
# ---------------------------------------------------------------

def test_server_health():
    print("--- Test 1: Server Health ---")
    if check_server():
        print("  [PASS] Server is running")
        return True
    else:
        print("  [FAIL] Server is NOT running at", BASE_URL)
        print("  TIP: Start it with: cd server && uvicorn main:app --port 8001")
        return False


# ---------------------------------------------------------------
# TEST 2: /process Endpoint -- Text File
# ---------------------------------------------------------------

def test_process_text_file():
    print("\n--- Test 2: Process Text File (Full Pipeline) ---")
    
    test_file = create_test_file(".txt")
    
    try:
        with open(test_file, "rb") as f:
            response = requests.post(
                f"{BASE_URL}/analysis/process",
                files={"file": ("test_lecture.txt", f, "text/plain")},
                data={
                    "user_id": TEST_USER_ID,
                    "subject_id": TEST_SUBJECT_ID,
                    "title": "Integration Test Lecture"
                },
                timeout=120  # AI can take time
            )

        print(f"  Status: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(f"  [PASS] Pipeline returned successfully!")
            print(f"  Engine: {data.get('engine_used', '?')}")
            print(f"  Lecture ID: {data.get('lecture_id', '?')}")
            preview = str(data.get('summary_preview', '?'))[:80]
            print(f"  Preview: {preview}...")
            return data
        else:
            print(f"  [FAIL] {response.text[:300]}")
            return None
    finally:
        os.unlink(test_file)


# ---------------------------------------------------------------
# TEST 3: /process Endpoint -- Audio File (if provided)
# ---------------------------------------------------------------

def test_process_audio_file(audio_path):
    print(f"\n--- Test 3: Process Audio File ({os.path.basename(audio_path)}) ---")
    
    if not os.path.exists(audio_path):
        print(f"  [WARN] Audio file not found: {audio_path}")
        return None
    
    mime_types = {".mp3": "audio/mpeg", ".wav": "audio/wav", ".mp4": "video/mp4"}
    ext = os.path.splitext(audio_path)[1].lower()
    mime = mime_types.get(ext, "application/octet-stream")

    with open(audio_path, "rb") as f:
        response = requests.post(
            f"{BASE_URL}/analysis/process",
            files={"file": (os.path.basename(audio_path), f, mime)},
            data={
                "user_id": TEST_USER_ID,
                "subject_id": TEST_SUBJECT_ID,
                "title": f"Audio Test - {os.path.basename(audio_path)}"
            },
            timeout=180  # Audio processing takes longer
        )

    print(f"  Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"  [PASS] Audio pipeline returned successfully!")
        print(f"  Engine: {data.get('engine_used', '?')}")
        print(f"  Lecture ID: {data.get('lecture_id', '?')}")
        return data
    else:
        print(f"  [FAIL] {response.text[:300]}")
        return None


# ---------------------------------------------------------------
# TEST 4: Chat Endpoint
# ---------------------------------------------------------------

def test_chat_endpoint():
    print("\n--- Test 4: Chat /ask Endpoint ---")
    
    response = requests.post(
        f"{BASE_URL}/chat/ask",
        data={
            "question": "What is machine learning?",
            "context": "We are studying AI and neural networks.",
            "user_id": TEST_USER_ID
        },
        timeout=30
    )

    print(f"  Status: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        answer = data.get("answer", "")
        print(f"  [PASS] Chat responded!")
        print(f"  Answer: {answer[:150]}...")
        return data
    else:
        print(f"  [FAIL] {response.text[:300]}")
        return None


# ---------------------------------------------------------------
# TEST 5: Syllabus Upload
# ---------------------------------------------------------------

def test_syllabus_upload():
    print("\n--- Test 5: Syllabus Upload /ingest/upload ---")
    
    test_file = create_test_file(".txt", content="SYLLABUS\n\nWeek 1: Introduction to AI\nWeek 2: Machine Learning\nWeek 3: Neural Networks")
    
    try:
        with open(test_file, "rb") as f:
            response = requests.post(
                f"{BASE_URL}/ingest/upload",
                files={"file": ("test_syllabus.txt", f, "text/plain")},
                data={
                    "user_id": TEST_USER_ID,
                    "subject_id": TEST_SUBJECT_ID,
                    "title": "Test Syllabus"
                },
                timeout=30
            )

        print(f"  Status: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print(f"  [PASS] Syllabus uploaded!")
            print(f"  ID: {data.get('id', '?')}")
            return data
        else:
            print(f"  [FAIL] {response.text[:300]}")
            return None
    finally:
        os.unlink(test_file)


# ---------------------------------------------------------------
# TEST 6: Verify JSON output structure from /process
# ---------------------------------------------------------------

def test_json_output_structure(process_result):
    print("\n--- Test 6: Validate JSON Output Structure ---")
    
    if not process_result:
        print("  [SKIP] No process result to validate")
        return

    required_keys = ["status", "lecture_id", "engine_used", "summary_preview"]
    missing = [k for k in required_keys if k not in process_result]
    
    if missing:
        print(f"  [FAIL] Missing keys: {missing}")
    else:
        print(f"  [PASS] All required keys present: {required_keys}")

    # Validate types
    assert isinstance(process_result.get("lecture_id"), str), "lecture_id should be string"
    assert isinstance(process_result.get("engine_used"), str), "engine_used should be string"
    print(f"  [PASS] Types validated")


# ---------------------------------------------------------------
# MAIN RUNNER
# ---------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 60)
    print("  LumenAI -- Integration Test Suite")
    print("=" * 60)

    results = {}
    start_time = time.time()

    # Test 1: Server health
    if not test_server_health():
        print("\n[STOP] Cannot proceed without a running server. Exiting.")
        sys.exit(1)

    # Test 2: Process text file
    results["process_text"] = test_process_text_file()

    # Test 3: Process audio (if argument given)
    if len(sys.argv) > 1:
        results["process_audio"] = test_process_audio_file(sys.argv[1])
    else:
        print("\n--- Test 3: Audio File (SKIPPED -- no file provided) ---")
        print("  TIP: Run with: python tests/test_audio_pipeline.py file.mp3")

    # Test 4: Chat
    results["chat"] = test_chat_endpoint()

    # Test 5: Syllabus upload
    results["syllabus"] = test_syllabus_upload()

    # Test 6: Validate output structure
    test_json_output_structure(results.get("process_text"))

    # Summary
    elapsed = time.time() - start_time
    passed = sum(1 for v in results.values() if v is not None)
    total = len(results)

    print("\n" + "=" * 60)
    print(f"  Results: {passed}/{total} passed | Time: {elapsed:.1f}s")
    print("=" * 60)

    # Save results to file
    results_file = os.path.join(os.path.dirname(__file__), "integration_results.json")
    with open(results_file, "w") as f:
        json.dump({
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "passed": passed,
            "total": total,
            "elapsed_seconds": round(elapsed, 1),
            "tests": {k: ("PASS" if v else "FAIL") for k, v in results.items()}
        }, f, indent=2)
    print(f"\nResults saved to: {results_file}")
