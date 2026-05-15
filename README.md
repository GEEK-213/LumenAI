# LumenAI 🌟

![LumenAI Banner](https://img.shields.io/badge/LumenAI-AI%20Study%20Companion-6200ea?style=for-the-badge)

LumenAI is a powerful, AI-driven study companion and note-taking application designed to revolutionize how students and professionals learn. By leveraging advanced artificial intelligence, LumenAI automatically transforms lectures, audio recordings, and documents into comprehensive study materials, including summaries, flashcards, and interactive quizzes.

## ✨ Key Features

- **📄 Smart Document Processing**: Upload PDF documents, syllabi, or lecture notes, and let the AI extract and structure the key information.
- **🎙️ Audio Transcription**: Record live lectures or upload audio files. LumenAI uses OpenAI's Whisper model to transcribe audio with high accuracy.
- **🧠 Automated Study Materials**: Automatically generate detailed summaries, interactive flashcards, and quizzes from your notes.
- **🚀 Seamless AI Fallback Architecture**: Primarily powered by Google's Gemini AI for lightning-fast processing, with an automatic failover to local, privacy-first LLMs (via Ollama) when cloud rate limits are reached.
- **🔒 Secure & Sync**: Powered by Supabase for robust authentication and real-time database syncing across devices.

## 🛠️ Technology Stack

**Frontend (Mobile & Web)**
- [Flutter](https://flutter.dev/) (Dart)
- Provider (State Management)
- Supabase Flutter SDK

**Backend (API & AI Processing)**
- [Python 3.10+](https://www.python.org/)
- [FastAPI](https://fastapi.tiangolo.com/) (Web Framework)
- Google Gemini API (Primary LLM)
- [Ollama](https://ollama.com/) & LLaMA 3.2 (Local Fallback LLM)
- OpenAI Whisper (Audio Transcription)
- Supabase (PostgreSQL Database & Auth)

---

## 🚀 Getting Started

Follow these instructions to set up the LumenAI project locally for development and testing.

### Prerequisites

Ensure you have the following installed on your local machine:
- **Python 3.10+**
- **Flutter SDK** (v3.10.4 or higher)
- **Ollama** (Optional, but highly recommended for local AI fallback)
- **FFmpeg** (Required for audio processing via Whisper)

---

### 1. Backend Setup (FastAPI)

The backend handles AI processing, database connections, document parsing, and transcription.

1. **Navigate to the server directory:**
   ```bash
   cd server
   ```

2. **Set up a Python Virtual Environment:**
   ```bash
   python -m venv venv
   
   # Windows:
   venv\Scripts\activate
   # Mac/Linux:
   source venv/bin/activate
   ```

3. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure Environment Variables:**
   Create a `.env` file in the `server/` directory and add your keys:
   ```env
   Gemini_API_key=YOUR_GEMINI_KEY
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_KEY
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   USE_LOCAL_LLM=true
   OLLAMA_MODEL=llama3.2
   WHISPER_MODEL=base
   ```

5. **Start the Server:**
   ```bash
   python main.py
   ```
   *The server will run on `http://0.0.0.0:8001`.*

---

### 2. Local AI Setup (Ollama Fallback)

To ensure uninterrupted service when Gemini rate limits are reached, set up Ollama.

1. **Download the model:**
   ```bash
   ollama run llama3.2
   ```
   *(Type `/bye` to exit once downloaded).*

2. **Run Ollama in the background:**
   ```bash
   ollama serve
   ```

---

### 3. Frontend Setup (Flutter)

The Flutter app connects to the local backend and Supabase.

1. **Navigate to the app directory:**
   ```bash
   cd app
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Application:**
   Connect a device, start an emulator, or run on web/desktop.
   ```bash
   flutter run
   ```

---

## 🧪 Testing the AI Failover

LumenAI is built with resilience in mind. You can test the automatic failover mechanism from Cloud (Gemini) to Local (Ollama):

1. **Happy Path (Gemini):** Upload a document in the app. Check the backend terminal for `🚀 Processing Lecture: ...` to ensure Gemini is handling the request.
2. **Fallback Path (Ollama):** Temporarily invalidate your `Gemini_API_key` in the `.env` file and restart the server. Upload a document. The backend terminal will show `⚠️ Gemini quota limit hit` and `🔄 Falling back to Local LLM (Ollama)...`, successfully generating your study materials using your local machine.

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

Please refer to the `TEAM_SETUP_AND_TESTING.md` for more detailed testing protocols.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
