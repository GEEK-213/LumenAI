# Lumen AI - Team Setup & Testing Guide

Welcome to the Lumen AI project repository! This guide contains everything you need to know to get the application running locally, test the AI features, and understand the failover mechanics.

---

## 🏗️ 1. Prerequisites (What You Need Installed)

Before you begin, ensure you have the following installed on your machine:
- **Python 3.10+**: For the backend server.
- **Flutter SDK**: For running the mobile/web app.
- **Ollama**: (Optional but highly recommended) For the local AI fallback when Google's Gemini API hits its free-tier limits.
  - Download from: [ollama.com](https://ollama.com/)

---

## ⚙️ 2. Backend Setup (The Brain)

The backend handles AI processing, database connections, and file parsing.

### Step 1: Navigate to the server folder
```bash
cd server
```

### Step 2: Set up a Python Virtual Environment (Recommended)
```bash
python -m venv venv

# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```
*(Note: If you encounter issues with PDF extraction, run `pip install markitdown[pdf]` manually).*

### Step 4: Environment Variables (`.env`)
Ensure you have a `.env` file inside the `server/` directory. It should look like this (get the actual keys from the team lead):
```env
Gemini_API_key=YOUR_GEMINI_KEY
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_KEY
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
USE_LOCAL_LLM=true
OLLAMA_MODEL=llama3.2
WHISPER_MODEL=base
```

### Step 5: Start the Server
```bash
python main.py
```
You should see output like: `Uvicorn running on http://0.0.0.0:8001 (Press CTRL+C to quit)`

---

## 🦙 3. Local AI Setup (Ollama Fallback)

Lumen AI uses Google Gemini. However, Gemini has strict "Free Tier" rate limits (15 requests/minute). If we hit the limit, the app **automatically fails over** to a local AI running on your computer.

### Step 1: Install the Local Model
Open a new terminal window and run:
```bash
ollama run llama3.2
```
*This will download the model (a couple of gigabytes). Once downloaded, type `/bye` to exit the chat prompt.*

### Step 2: Run Ollama in the Background
Ollama usually runs as a background service automatically. If not, run:
```bash
ollama serve
```

---

## 📱 4. Frontend Setup (The App)

The Flutter application connects to your local backend and Supabase.

### Step 1: Navigate to the app folder
Open a *new* terminal window (keep the backend server running!).
```bash
cd app
```

### Step 2: Install Flutter Packages
```bash
flutter pub get
```

### Step 3: Run the App
Connect a physical device, start an Android Emulator, or run on web/desktop.
```bash
flutter run
```

---

## 🧪 5. How to Test the App

Once both the backend and frontend are running, follow these steps to verify everything is working beautifully:

### Scenario A: The Happy Path (Gemini Processing)
1. Open the app and log in (or create an account).
2. Go to the Notes/Recorder section.
3. Upload a document (like a PDF syllabus or lecture) or record an audio clip.
4. **Check the backend terminal:** You should see `🚀 Processing Lecture: ...` and it should process using Gemini.
5. **Check the app:** Once complete, check if the summary, flashcards, and quizzes appear on your screen correctly.

### Scenario B: The Quota Fallback Test (Ollama Processing)
We need to make sure the app survives when Google gets mad at us for sending too many requests.
1. Force Gemini to fail by spamming the upload button 15+ times quickly, OR temporarily mess up the `Gemini_API_key` in your `.env` file (and restart the backend).
2. Upload a document.
3. **Check the backend terminal:** You should see:
   `⚠️ Gemini quota limit hit`
   `🔄 Falling back to Local LLM (Ollama)...`
   `🤖 Sending to local Ollama model: llama3.2`
4. Wait a bit longer (local AI is slower than Cloud API).
5. **Check the app:** The content should still generate and appear in the UI without crashing!

### Common Errors You Might See
- **`500 Internal Server Error: Failed to connect to Ollama`**: Your local Ollama app isn't running. Open the Ollama app or run `ollama serve`.
- **`429 Too Many Requests`**: You hit the Gemini limit AND you turned off `USE_LOCAL_LLM=true` in the `.env`. Just wait 60 seconds.
- **Audio processing fails**: You might need to install `ffmpeg` securely on your OS for the `openai-whisper` library to work properly.


