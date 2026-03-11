# LUMEN AI — Updated Project Documentation

> **Note to team:** This document contains the updated text for all sections of the final project documentation. Copy each section into your Word/PDF document, replacing the corresponding old content. Sections marked **[NEW]** are entirely new and should be inserted at the appropriate location.

---

# CHAPTER 1: ANALYSIS

## 1. Analysis

With the rapid advancement of artificial intelligence and its integration into educational environments, AI-powered learning applications are becoming essential tools in modern academic workflows. This project presents **Lumen AI: Illuminate Your Learning** — a comprehensive, cross-platform educational support application designed for students across all academic levels.

Lumen AI automates the note-taking process by allowing users to upload documents (PDF, DOCX, PPTX) or record lecture audio, which is then processed through advanced AI models to generate structured study artifacts including summaries, interactive quizzes, flashcards, mind maps, code sandboxes, and audio podcasts. The platform integrates a Retrieval-Augmented Generation (RAG) chatbot that enables students to ask questions grounded in their specific lecture and syllabus content, as well as a conversational voice tutor for hands-free study sessions.

Beyond content automation, Lumen AI incorporates a full gamification engine with virtual currency (Lumen Coins), global leaderboards, and a themed reward store to sustain student engagement. The application operates across **Android, Windows desktop, and Web** platforms through Flutter's cross-compilation capabilities, featuring adaptive navigation that automatically switches between mobile and desktop layouts.

## 1.1 Proposed System

Lumen AI is a production-grade educational support application that transforms raw lecture content into a comprehensive suite of active learning materials. The system architecture follows a client-server model:

- **Frontend:** A Flutter-based cross-platform application (Android, Windows, Web) providing responsive, themed user interfaces with adaptive navigation (BottomNavigationBar on mobile, NavigationRail on desktop).
- **Backend:** A Python FastAPI server handling AI orchestration, file processing, and API management with JWT-secured endpoints.
- **AI Layer:** Google Gemini (primary) and Ollama (local fallback) LLMs for content analysis and generation.
- **Database:** Supabase (PostgreSQL) with Row-Level Security for user data isolation, authentication, and file storage.

### 1.1.1 Objectives

1. **Automate Lecture Processing:** Transform raw audio recordings and documents (PDF, DOCX, PPTX) into structured, multi-format study artifacts including summaries, quizzes, flashcards, mind maps, code sandboxes, and audio podcasts.

2. **Provide Intelligent Academic Support:** Deliver context-aware Q&A through Retrieval-Augmented Generation (RAG), grounding AI responses in the student's specific lecture and syllabus content to minimize hallucination.

3. **Enable Hands-Free Voice Tutoring:** Integrate real-time speech-to-text and text-to-speech pipelines for a conversational voice tutor experience, allowing students to study without screen interaction.

4. **Gamify the Learning Process:** Implement a comprehensive gamification engine with virtual currency (Lumen Coins), experience points, ranked tiers, global leaderboards, and a themed reward store to sustain long-term engagement.

5. **Support Visual Knowledge Organization:** Provide an infinite spatial canvas where students can pin and arrange mind map nodes and flashcards from multiple lectures onto a shared, zoomable workspace for cross-lecture concept mapping.

6. **Ensure Production-Grade Security:** Implement JWT authentication, Row-Level Security, encrypted token storage, rate limiting, and input validation to protect student data.

7. **Deliver Cross-Platform Accessibility:** Build a single codebase that runs natively on Android, Windows desktop, and Web browsers with adaptive layouts, keyboard shortcuts, and responsive navigation.

8. **Automate Syllabus Organization:** Use AI to automatically classify uploaded lectures into the correct syllabus units with confidence scoring, reducing manual organizational overhead.

### 1.1.2 Features

#### Core AI Features
1. **Automated Lecture Processing & Smart Note Generation** — Supports audio (MP3, WAV, M4A, WEBM) and document (PDF, DOCX, PPTX) uploads. After processing through Gemini/Ollama, the system generates structured summaries with headings, key points, and exam alerts.

2. **Interactive Quiz Engine** — AI-generated multiple-choice quizzes with scoring (8/10 display), completion modals, retake functionality, and dynamic LLM-powered novel question generation for each retake attempt. Keyboard shortcut support (keys 1-4) on desktop.

3. **Swipeable Flashcard Deck** — Tinder-style PageView flashcards with "Know it" / "Review" confidence buttons, mastery summary tracking, and AI-powered generation of additional cards. Arrow key navigation and Space/Enter shortcuts on desktop.

4. **Mind Map Visualization** — Interactive graph-based mind maps using radial tree layout with InteractiveViewer for pan/zoom. Supports double-tap node expansion for deeper definitions.

5. **Code Sandbox** — When programming topics are detected, the AI generates executable code snippets displayed in a dedicated Code Sandbox tab.

6. **LumenCast Podcasts** — AI generates a conversational dialogue script from lecture content, which is then converted to audio via gTTS, playable through an integrated audio player with seek, play/pause controls.

7. **RAG-Powered AI Chatbot** — Contextual Q&A grounded in lecture transcripts and syllabus content using Retrieval-Augmented Generation. Supports multi-turn conversations and subject-specific context selection.

8. **Conversational Voice Tutor** — Full-screen voice tutoring interface with real-time speech-to-text (speech_to_text), AI processing via RAG, and spoken responses via text-to-speech (flutter_tts). Features pulsing mic animation, waveform visualization, and conversation history.

9. **Infinite Spatial Canvas** — Zoomable, pannable workspace (3000×3000 virtual canvas) where students pin mind map nodes and flashcards from multiple lectures. Draggable positioning with persistent storage in Supabase.

10. **Smart Syllabus Auto-Mapping** — AI automatically classifies uploaded lectures into correct syllabus units using Gemini-powered content matching with confidence scoring (0.0–1.0). Auto-applies high-confidence (≥0.7) suggestions.

#### Engagement & Gamification Features
11. **Lumen Coins Economy** — Virtual currency awarded for quiz performance (+10/correct, +50/streak milestone, +5/daily login). Persistent wallet display on NotesPage.

12. **Global Leaderboard** — Ranked display of top users by XP with tier badges (Novice → Scholar → Grandmaster).

13. **Themed Avatar Marketplace** — Store where users spend Lumen Coins on cosmetic themes (Cyberpunk, Sketch, Neon) and AI avatar personas with full-app color scheme changes.

#### Platform & Infrastructure Features
14. **Google Classroom Integration** — OAuth-based sync that imports courses, assignments, and deadlines into the LumenAI calendar.

15. **Adaptive Cross-Platform UI** — NavigationRail on desktop (≥800px width), BottomNavigationBar on mobile. Keyboard shortcuts for study interactions.

16. **Production Security** — JWT authentication, RLS policies, Fernet-encrypted OAuth tokens, slowapi rate limiting, Pydantic input validation.

17. **Automated Testing & CI/CD** — Pytest backend tests, Flutter widget tests, GitHub Actions CI/CD pipeline.

### 1.1.3 Intended Audience

*(Keep the existing content — High School, University, Postgraduate students — as it remains accurate.)*

### 1.1.4 Assumptions and Dependencies

1. The user has a stable internet connection for AI processing and cloud synchronization.
2. Audio recordings are in English language with reasonable clarity.
3. The Google Gemini API is accessible; if unavailable, the system falls back to a locally hosted Ollama model.
4. Supabase free-tier limitations apply for database and storage capacity.
5. For Windows desktop, the user runs Windows 10 or higher.
6. For Web, the user has a modern browser (Chrome, Edge, Firefox) with JavaScript enabled.

## 1.2 Hardware and Software Specification

### 1.2.1 Hardware Requirements

**Development Environment:**
- Windows 10/11 operating system
- VS Code as the primary IDE with Flutter, Dart, and Python extensions
- Minimum 8GB RAM for concurrent Flutter and backend development
- Git for version control

**User Device Compatibility:**

| Platform | Requirements |
|----------|-------------|
| **Android** | Android 8.0+ (API 26+), 4GB RAM, microphone access, internet |
| **Windows Desktop** | Windows 10+, 4GB RAM, 800×600 minimum display |
| **Web** | Modern browser (Chrome 90+, Edge 90+, Firefox 90+), internet |

### 1.2.2 Software Requirements

| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.x | Cross-platform UI framework (Android, Windows, Web) |
| Dart | 3.x | Frontend programming language |
| FastAPI | 0.100+ | Python REST API backend framework |
| Python | 3.11+ | Backend programming language |
| Google Gemini API | gemini-2.0-flash | Primary LLM for lecture analysis and RAG |
| Ollama | Latest | Local LLM fallback (Mistral/LLaMA) |
| Supabase | Cloud | PostgreSQL database, authentication, file storage |
| gTTS | 2.x | Server-side text-to-speech for podcast generation |
| speech_to_text | 7.x | Flutter package for voice input recognition |
| flutter_tts | 4.x | Flutter package for spoken AI responses |
| PyPDF2 | 3.x | PDF text extraction |
| python-docx | 0.8+ | DOCX text extraction |
| python-pptx | 0.6+ | PPTX text extraction |
| slowapi | 0.1+ | API rate limiting middleware |
| Pydantic | 2.x | Request validation models |
| cryptography (Fernet) | 41+ | OAuth token encryption at rest |
| GitHub Actions | — | CI/CD for automated testing |
| VS Code | Latest | Development IDE |

---

# CHAPTER 2: DESIGNS

*(Replace each diagram with the updated versions from the `diagrams.md` file in the docs folder.)*

---

# CHAPTER 3: IMPLEMENTATION

## 3.1 User Interface

### 3.1.1 Auth Module
*(Keep existing Register and Login screenshots — verify they still match current UI.)*

### 3.1.2 App User Profile
**UPDATE:** The profile now includes Lumen Coins wallet display, XP rank badge, and avatar selection. Add new screenshots showing coins balance and rank tier.

### 3.1.3 Home Page [NEW]
The home page features a themed header with the user's active theme (Default, Cyberpunk, Sketch, or Neon), quick-access cards for recent lectures, and a navigation grid for all primary functions. Themes apply globally across all pages, changing color schemes, fonts, and visual effects.

### 3.1.4 Store & Marketplace [NEW]
The Store page displays themed cosmetic items (Cyberpunk, Sketch, Neon themes) and AI avatar personas purchasable with Lumen Coins. Each item shows a coin price, preview, and purchase button.

### 3.1.5 Global Leaderboard [NEW]
The Leaderboard page ranks all users by XP, displaying rank tier badges, coin totals, and streak counts. Users can see their own position relative to the global rankings.

## 3.2 Functionality Design

### 3.2.1 Notes
**UPDATE:** Notes page now includes a coin wallet display, subject management with color-coded cards, and within each subject: a "Canvas" FAB button to open the Spatial Canvas, and "Map" chips on unmapped lectures for auto-mapping suggestions.

### 3.2.2 Calendar
*(Keep existing — verify screenshots match current UI.)*

### 3.2.3 Chatbot
**UPDATE:** The chatbot now includes a microphone button in the input area that opens the Voice Tutor page. The chat supports multi-turn conversations and subject-specific context selection.

### 3.2.4 Flashcards
**REPLACE:** The flashcard interface has been completely redesigned from a GridView to a swipeable PageView (Tinder-style). Features include:
- Progress bar showing card position (e.g., "Card 3 of 10")
- "Know it" ✅ and "Review" 🔄 confidence buttons
- Running tally of known vs. review counts
- Mastery summary at deck completion
- "Generate More" button for AI-powered novel card creation
- Keyboard shortcuts on desktop (←/→ navigate, Space = know, Enter = review)

### 3.2.5 Quizzes
**REPLACE:** The quiz interface now includes:
- Score tracker bar with progress indicator (e.g., "5/10 answered")
- Colored score badge showing correct count
- Completion modal with percentage, emoji rating, and coin award
- "Retake Quiz" button that generates entirely novel AI questions (not repeats)
- Keyboard shortcuts on desktop (1-4 to select answers)

### 3.2.6 Results
**REPLACE:** The results page now has a comprehensive TabBar with 6 tabs:
1. **Summary** — Formatted markdown with headings and exam alerts
2. **Quiz** — Enhanced quiz with scoring and retake
3. **Flashcards** — Swipeable deck with mastery tracking
4. **Mind Map** — Interactive graph with pan/zoom
5. **Code** — Code sandbox (appears only when code snippets are detected)
6. **Podcast** — LumenCast audio player with seek/play controls

### 3.2.7 Voice Tutor [NEW]
Full-screen voice tutoring interface:
- Pulsing microphone button for voice input
- Real-time transcription display
- Waveform animation during AI processing
- Subject selector for grounding responses
- Auto-playback of AI answers via text-to-speech
- Conversation history chips for revisiting Q&A pairs

### 3.2.8 Spatial Canvas [NEW]
Infinite zoomable workspace for visual knowledge organization:
- InteractiveViewer with 0.1x–4x zoom on a 3000×3000 virtual canvas
- Content drawer showing items from all analyzed lectures
- Draggable mind map node and flashcard pin widgets
- Color-coded by lecture source
- Persistent pin positions stored in database

### 3.2.9 Desktop Navigation [NEW]
On screens wider than 800px, the app switches to a NavigationRail layout:
- Branded Lumen logo at the top
- Four navigation destinations (Home, Projects, Notes, Profile)
- Recorder button at the bottom of the rail
- Smooth transition when resizing window

## 3.3 Testing

**[NEW SECTION]**

### 3.3.1 Backend Testing (Pytest)
- Integration tests covering `/analyze`, `/ask`, `/classroom`, `/ingestion` endpoints
- Mocked Gemini/Ollama responses for deterministic testing without live API keys
- Edge case tests for corrupt audio, oversized uploads, and malformed AI responses

### 3.3.2 Frontend Testing (Flutter)
- Widget tests for `NotesPage`, `AIChatPage`, `MasterCalendarPage`
- Service tests mocking `ApiService` HTTP calls
- Model serialization/deserialization tests for `data_models.dart`

### 3.3.3 CI/CD Pipeline (GitHub Actions)
- Automated `flutter analyze` + `flutter test` on every push
- Automated `pytest` for backend validation
- Runs on pull requests to prevent regressions

## 3.4 Security Architecture [NEW SECTION]

| Security Layer | Implementation |
|---------------|---------------|
| **Authentication** | Supabase Auth with email/password, JWT session tokens |
| **API Authorization** | JWT verification middleware on all FastAPI endpoints |
| **Data Isolation** | Row-Level Security (RLS) policies on all database tables |
| **Token Encryption** | Google OAuth tokens encrypted at rest using Fernet symmetric encryption |
| **Rate Limiting** | slowapi middleware preventing API abuse |
| **Input Validation** | Pydantic models validating all incoming request data |
| **Secret Management** | Environment variables via `.env` files (never hardcoded) |

---

# CHAPTER 4: CONCLUSION AND FUTURE GOALS

## 4.1 Conclusion

The development of Lumen AI represents a comprehensive effort to integrate artificial intelligence into everyday academic workflows at a production-grade level. Over seven structured development phases, the project evolved from a basic Android prototype into a feature-rich, cross-platform learning assistant that runs on Android, Windows desktop, and modern web browsers.

**Key achievements include:**

- **Automated Lecture Processing:** Students can upload audio recordings, PDFs, DOCX, and PPTX files, which are automatically processed through Google Gemini (with Ollama fallback) to generate six types of study artifacts: structured summaries, interactive quizzes, swipeable flashcards, mind maps, code sandboxes, and audio podcasts.

- **Intelligent Tutoring:** The RAG-powered chatbot provides context-grounded answers based on specific lecture and syllabus content, while the Voice Tutor enables hands-free study through real-time speech-to-text and text-to-speech pipelines.

- **Gamification Engine:** A complete engagement system with Lumen Coins, XP ranks, global leaderboards, and a themed reward store sustains long-term student motivation.

- **Production Security:** JWT authentication, Row-Level Security, encrypted token storage, rate limiting, and automated CI/CD testing ensure the application meets production standards.

- **Cross-Platform Delivery:** Adaptive navigation (NavigationRail on desktop, BottomNavBar on mobile), keyboard shortcuts for power users, and responsive layouts ensure a premium experience across all platforms.

Lumen AI demonstrates that generative AI can meaningfully transform passive lecture content into active, personalized learning experiences — combining automation, intelligence, engagement, and accessibility within a single, cohesive platform.

## 4.2 Future Goals

1. **Spaced Repetition System (SRS):** Implement the SM-2 algorithm to schedule flashcard reviews based on individual forgetting curves, with a daily "Today's Reviews" queue on the home page.

2. **Offline Mode:** Cache lectures, flashcards, and summaries using local storage (sqflite) for review without internet connectivity, with automatic synchronization when connection is restored.

3. **Learning Analytics Dashboard:** Build a GitHub-style study activity heatmap showing daily study minutes, alongside weak-area detection that flags topics with consistently low quiz scores.

4. **Peer-to-Peer Flashcard Battles:** Real-time WebSocket-based flashcard duels where students challenge classmates to timed matching competitions.

5. **Multi-Language Support:** Extend lecture processing and artifact generation to non-English languages through multilingual speech recognition and content generation.

6. **App Store Deployment:** Publish to Google Play Store and Apple App Store with compliance, performance optimization, and enhanced security measures.

---

# CHAPTER 5: REFERENCES

1. Flutter Documentation — https://docs.flutter.dev/
2. Dart Programming Language — https://dart.dev/guides
3. FastAPI Documentation — https://fastapi.tiangolo.com/
4. Python Documentation — https://docs.python.org/3/
5. Supabase Documentation — https://supabase.com/docs
6. Google Gemini API — https://ai.google.dev/docs
7. Ollama Documentation — https://ollama.ai/
8. gTTS (Google Text-to-Speech) — https://pypi.org/project/gTTS/
9. speech_to_text (Flutter) — https://pub.dev/packages/speech_to_text
10. flutter_tts (Flutter) — https://pub.dev/packages/flutter_tts
11. PyPDF2 — https://pypi.org/project/PyPDF2/
12. python-docx — https://python-docx.readthedocs.io/
13. python-pptx — https://python-pptx.readthedocs.io/
14. slowapi — https://pypi.org/project/slowapi/
15. GitHub Actions — https://docs.github.com/en/actions
16. Android Developer Documentation — https://developer.android.com/
17. Kiewra, K.A. (1989). "A review of note-taking: The encoding-storage paradigm and beyond." *Educational Psychology Review*, 1(2), 147-172.
18. Lewis, P., et al. (2020). "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks." *NeurIPS*, 33, 9459-9474.
19. Holmes, W., Bialik, M., & Fadel, C. (2019). *Artificial Intelligence in Education.* Center for Curriculum Redesign.
20. Deterding, S., et al. (2011). "From game design elements to gamefulness." *MindTrek*, 9-15.
