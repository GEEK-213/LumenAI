# LumenAI — Updated Diagrams

> **Instructions:** Render these Mermaid diagrams using https://mermaid.live/ or a Mermaid plugin, then export as PNG images to paste into your Word/PDF document.

---

## 2.1 Use Case Diagram

```mermaid
graph TB
    subgraph Student["👤 Student"]
        direction TB
    end

    subgraph LumenAI["🧠 LumenAI System"]
        UC1["Upload Lecture<br/>(Audio/PDF/DOCX/PPTX)"]
        UC2["View AI Summary"]
        UC3["Take Quiz"]
        UC4["Review Flashcards"]
        UC5["View Mind Map"]
        UC6["Use Code Sandbox"]
        UC7["Listen to Podcast"]
        UC8["Chat with AI Tutor<br/>(RAG)"]
        UC9["Voice Tutor Session"]
        UC10["Pin to Spatial Canvas"]
        UC11["Manage Subjects & Units"]
        UC12["Auto-Map Lectures"]
        UC13["Earn Lumen Coins"]
        UC14["View Leaderboard"]
        UC15["Buy Themes & Avatars"]
        UC16["Sync Google Classroom"]
        UC17["View Calendar"]
        UC18["Edit Profile"]
    end

    subgraph External["⚡ External Services"]
        GeminiAPI["Google Gemini API"]
        OllamaLLM["Ollama Local LLM"]
        SupabaseDB["Supabase<br/>(DB + Auth + Storage)"]
        GoogleCR["Google Classroom API"]
        TTS["gTTS / flutter_tts"]
        STT["speech_to_text"]
    end

    Student --> UC1
    Student --> UC2
    Student --> UC3
    Student --> UC4
    Student --> UC5
    Student --> UC6
    Student --> UC7
    Student --> UC8
    Student --> UC9
    Student --> UC10
    Student --> UC11
    Student --> UC12
    Student --> UC13
    Student --> UC14
    Student --> UC15
    Student --> UC16
    Student --> UC17
    Student --> UC18

    UC1 --> GeminiAPI
    UC1 --> OllamaLLM
    UC1 --> SupabaseDB
    UC8 --> GeminiAPI
    UC9 --> STT
    UC9 --> GeminiAPI
    UC9 --> TTS
    UC7 --> TTS
    UC12 --> GeminiAPI
    UC16 --> GoogleCR
    UC13 --> SupabaseDB
```

---

## 2.2 ER Diagram (Entity-Relationship)

```mermaid
erDiagram
    USERS ||--o{ SUBJECTS : creates
    USERS ||--o| USER_PROFILES : has
    USERS ||--o| USER_INTEGRATIONS : has
    USERS ||--o{ CANVAS_PINS : creates
    USERS ||--o{ CALENDAR_EVENTS : has

    SUBJECTS ||--o{ UNITS : contains
    SUBJECTS ||--o{ LECTURES : contains
    SUBJECTS ||--o{ CANVAS_PINS : "pins from"

    UNITS ||--o{ LECTURES : "mapped to"
    UNITS ||--o{ AUTO_MAP_LOG : "suggested for"

    LECTURES ||--o| ANALYSIS_RESULTS : generates
    LECTURES ||--o{ AUTO_MAP_LOG : "mapped by"

    USERS {
        uuid id PK
        string email
        timestamp created_at
    }

    SUBJECTS {
        uuid id PK
        uuid user_id FK
        string name
        string description
        string color
        timestamp created_at
    }

    UNITS {
        uuid id PK
        uuid subject_id FK
        string title
        text description
        int order_index
    }

    LECTURES {
        uuid id PK
        uuid subject_id FK
        uuid unit_id FK
        string title
        string file_url
        string file_type
        text transcript
        timestamp created_at
    }

    ANALYSIS_RESULTS {
        uuid id PK
        uuid lecture_id FK
        text summary
        jsonb quiz_questions
        jsonb flashcards
        jsonb mind_map
        jsonb code_snippets
        text podcast_script
        string podcast_url
        timestamp created_at
    }

    USER_PROFILES {
        uuid id PK
        uuid user_id FK
        string display_name
        int coins
        int xp
        string rank
        string avatar
        string active_theme
        timestamp updated_at
    }

    USER_INTEGRATIONS {
        uuid id PK
        uuid user_id FK
        text google_tokens_encrypted
        string provider
        timestamp updated_at
    }

    CANVAS_PINS {
        uuid id PK
        uuid user_id FK
        uuid subject_id FK
        string pin_type
        string content_id
        string label
        float position_x
        float position_y
        string color
        jsonb metadata
        timestamp created_at
    }

    AUTO_MAP_LOG {
        uuid id PK
        uuid lecture_id FK
        uuid suggested_unit_id FK
        float confidence
        string status
        timestamp created_at
    }

    CALENDAR_EVENTS {
        uuid id PK
        uuid user_id FK
        string title
        text description
        string source
        timestamp event_date
        timestamp created_at
    }
```

---

## 2.3 Class Diagram

```mermaid
classDiagram
    class ApiService {
        -Supabase _supabase
        +analyzeFile(file, subjectId, title)
        +askQuestion(question, subjectId, lectureId)
        +getSubjects()
        +getLectures(subjectId)
        +getAnalysisResult(lectureId)
        +generatePodcast(lectureId)
        +generateNovelQuiz(lectureId)
        +generateNovelFlashcards(lectureId)
        +getCanvasPins(subjectId)
        +saveCanvasPin(pin)
        +updatePinPosition(pinId, x, y)
        +deleteCanvasPin(pinId)
        +getAutoMapSuggestion(lectureId)
        +applyAutoMap(lectureId, unitId)
        +remapLecture(lectureId)
        +awardCoins(userId, amount, reason)
        +getLeaderboard()
        +getUserProfile()
        +updateProfile(data)
        +purchaseStoreItem(itemId, cost)
    }

    class GamificationService {
        +awardQuizCoins(correct, total)
        +awardStreakBonus(streakCount)
        +awardDailyLogin()
        +calculateRank(xp)
    }

    class QuizService {
        +evaluateAnswer(question, selected)
        +calculateScore(answers, questions)
        +getScoreEmoji(percentage)
    }

    class ThemeProvider {
        -String _activeTheme
        +currentTheme ThemeData
        +setTheme(themeName)
        +availableThemes List
    }

    class MainPage {
        -int _currentIndex
        -List~Widget~ _pages
        +build() Widget
    }

    class AnalysisResultScreen {
        -AnalysisResult result
        -TabController _tabController
        +build() Widget
    }

    class EnhancedQuizTab {
        -List~QuizQuestion~ questions
        -Map selectedAnswers
        -int focusedQuizIndex
        +_selectAnswer(index, option)
        +_retakeQuiz()
    }

    class EnhancedFlashcardsTab {
        -List~FlashcardData~ flashcards
        -PageController _pageController
        -Map confidence
        +_markCard(isKnown)
    }

    class VoiceTutorPage {
        -SpeechToText _stt
        -FlutterTts _tts
        -bool _isListening
        +_startListening()
        +_stopAndProcess()
    }

    class SpatialCanvasPage {
        -TransformationController _controller
        -List~CanvasPin~ _pins
        +_addPin(type, content)
        +_updatePinPosition(id, x, y)
    }

    class AIChatPage {
        -List~Message~ _messages
        -String _selectedSubjectId
        +_sendMessage(text)
    }

    MainPage --> AnalysisResultScreen
    MainPage --> AIChatPage
    AnalysisResultScreen --> EnhancedQuizTab
    AnalysisResultScreen --> EnhancedFlashcardsTab
    AIChatPage --> VoiceTutorPage
    ApiService <.. AnalysisResultScreen
    ApiService <.. EnhancedQuizTab
    ApiService <.. VoiceTutorPage
    ApiService <.. SpatialCanvasPage
    GamificationService <.. EnhancedQuizTab
    QuizService <.. EnhancedQuizTab
    ThemeProvider <.. MainPage
```

---

## 2.4 Flowchart — Lecture Processing Pipeline

```mermaid
flowchart TD
    A["🎤 Student Uploads<br/>Audio / PDF / DOCX / PPTX"] --> B{"File Type?"}
    B -->|Audio| C["Upload to Supabase Storage"]
    B -->|PDF| D["Extract text via PyPDF2"]
    B -->|DOCX| E["Extract text via python-docx"]
    B -->|PPTX| F["Extract text via python-pptx"]

    C --> G["Send to Gemini API<br/>for transcription + analysis"]
    D --> G
    E --> G
    F --> G

    G --> H{"Gemini Available?"}
    H -->|Yes| I["Gemini processes content"]
    H -->|No| J["Fallback to Ollama<br/>(local LLM)"]
    J --> I

    I --> K["Parse JSON response"]
    K --> L["Store in analysis_results table"]

    L --> M["📝 Summary"]
    L --> N["❓ Quiz Questions"]
    L --> O["🃏 Flashcards"]
    L --> P["🗺️ Mind Map"]
    L --> Q["💻 Code Snippets"]

    L --> R{"Auto-Map Enabled?"}
    R -->|Yes| S["Gemini classifies<br/>lecture → unit"]
    S --> T{"Confidence ≥ 0.7?"}
    T -->|Yes| U["Auto-assign to unit"]
    T -->|No| V["Show suggestion<br/>to student"]
    R -->|No| W["Manual mapping"]

    style A fill:#1a1a2e,color:#fff
    style M fill:#0d47a1,color:#fff
    style N fill:#e65100,color:#fff
    style O fill:#1b5e20,color:#fff
    style P fill:#4a148c,color:#fff
    style Q fill:#bf360c,color:#fff
```

---

## 2.5 System Architecture Diagram

```mermaid
flowchart TB
    subgraph Client["📱 Flutter Client (Android / Windows / Web)"]
        HP["Home Page"]
        NP["Notes Page"]
        RP["Results Page<br/>(Summary, Quiz, Flashcards,<br/>Mind Map, Code, Podcast)"]
        CP["AI Chat Page"]
        VT["Voice Tutor"]
        SC["Spatial Canvas"]
        SP["Store Page"]
        LP["Leaderboard"]
        CAL["Calendar"]
        API["ApiService<br/>(HTTP Client)"]
    end

    subgraph Backend["⚙️ FastAPI Backend (Python)"]
        MW["JWT Auth Middleware<br/>+ Rate Limiter"]
        R1["/analyze"]
        R2["/ask (RAG)"]
        R3["/ingest"]
        R4["/classroom"]
        R5["/mapping"]
        R6["/podcast"]
        ENG["AI Engine<br/>(analyzer.py)"]
        LOC["Local Analyzer<br/>(local_analyzer.py)"]
        AMP["Auto-Mapper<br/>(auto_mapper.py)"]
        AUD["Audio Service<br/>(gTTS)"]
    end

    subgraph External["☁️ External Services"]
        GEM["Google Gemini API"]
        OLL["Ollama (Local LLM)"]
        SUP["Supabase<br/>(PostgreSQL + Auth<br/>+ Storage)"]
        GCR["Google Classroom API"]
    end

    API --> MW
    MW --> R1
    MW --> R2
    MW --> R3
    MW --> R4
    MW --> R5
    MW --> R6

    R1 --> ENG
    R2 --> ENG
    R5 --> AMP
    R6 --> AUD

    ENG --> GEM
    ENG -.->|fallback| LOC
    LOC --> OLL
    AMP --> GEM
    R4 --> GCR

    R1 --> SUP
    R2 --> SUP
    R3 --> SUP

    style Client fill:#0d1117,color:#58a6ff
    style Backend fill:#161b22,color:#f0883e
    style External fill:#21262d,color:#7ee787
```

---

## 2.6 Client Device Diagram

```mermaid
flowchart LR
    subgraph Devices["Supported Platforms"]
        MOBILE["📱 Android<br/>Mobile / Tablet<br/>(BottomNavigationBar)"]
        DESKTOP["🖥️ Windows Desktop<br/>1280×800 default<br/>(NavigationRail)"]
        WEB["🌐 Web Browser<br/>Chrome / Edge / Firefox<br/>(NavigationRail on wide,<br/>BottomNav on narrow)"]
    end

    subgraph App["Flutter App (Single Codebase)"]
        ADAPTIVE["Adaptive Layout<br/>< 800px → BottomNav<br/>≥ 800px → NavigationRail"]
        KEYBOARD["Keyboard Shortcuts<br/>←→ Navigate<br/>1-4 Quiz Answers<br/>Space/Enter Flashcards"]
    end

    subgraph Backend["Backend"]
        SERVER["FastAPI Server"]
        DB["Supabase Cloud"]
    end

    MOBILE --> App
    DESKTOP --> App
    WEB --> App
    App --> SERVER
    SERVER --> DB
```

---

## 2.7 Gamification Flow [NEW]

```mermaid
flowchart TD
    A["Student Completes<br/>an Action"] --> B{"Action Type?"}

    B -->|Quiz Answer| C["+10 Coins per<br/>correct answer"]
    B -->|Streak Milestone| D["+50 Coins<br/>at streak milestones"]
    B -->|Daily Login| E["+5 Coins"]

    C --> F["Update user_profiles<br/>(coins, xp)"]
    D --> F
    E --> F

    F --> G["Calculate Rank<br/>from XP total"]
    G --> H{"XP Range"}

    H -->|0-99| I["🔵 Novice"]
    H -->|100-499| J["🟢 Apprentice"]
    H -->|500-1499| K["🟡 Scholar"]
    H -->|1500-4999| L["🟠 Expert"]
    H -->|5000+| M["🔴 Grandmaster"]

    F --> N["Leaderboard<br/>Auto-updated"]
    F --> O["Wallet Balance<br/>Displayed in UI"]
    O --> P["Store Purchase<br/>(Themes & Avatars)"]

    style A fill:#1a1a2e,color:#fff
    style I fill:#2196F3,color:#fff
    style J fill:#4CAF50,color:#fff
    style K fill:#FFC107,color:#000
    style L fill:#FF9800,color:#fff
    style M fill:#F44336,color:#fff
```

---

## 2.8 Voice Tutor Flow [NEW]

```mermaid
flowchart TD
    A["🎤 Student taps<br/>Mic button"] --> B["speech_to_text<br/>starts listening"]
    B --> C["Real-time<br/>transcription displayed"]
    C --> D["Student stops speaking<br/>or taps stop"]
    D --> E["Transcribed text sent<br/>to /ask endpoint"]
    E --> F["RAG retrieves<br/>lecture + syllabus context"]
    F --> G["Gemini generates<br/>grounded response"]
    G --> H["Response displayed<br/>as text"]
    H --> I["flutter_tts speaks<br/>response aloud"]
    I --> J["Student can ask<br/>follow-up question"]
    J --> A

    style A fill:#4a148c,color:#fff
    style I fill:#0d47a1,color:#fff
```
