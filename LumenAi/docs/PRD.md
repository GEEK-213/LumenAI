Product Requirements Document (PRD): Lumen AI
Version: 2.0 (Syllabus-Grounded Architecture) Status: Active Development Developer: Mohammed Faaris Khan 
Tagline: "Illuminating the Path to Active Learning"

1. Executive Summary
Lumen AI is a cross-platform mobile application designed to bridge the gap between "Passive Listening" and "Active Learning." Unlike generic transcription tools, Lumen AI utilizes Syllabus-Grounded RAG (Retrieval-Augmented Generation). By ingesting a student's specific curriculum (Syllabus, PPTs, Textbooks), the AI filters out lecture noise and generates exam-centric study artifacts (Summaries, Mind Maps, Quizzes) that are strictly aligned with university requirements.

2. Problem & Solution
🔴 The Problem: The "Generic AI" Gap
Noise Signal: Professors often digress into personal anecdotes or off-topic discussions during lectures. Generic AI summarizers capture this "noise," wasting the student's study time.
Context Drift: A generic AI might explain "Polymorphism" using high-level industry terms, whereas the student needs the specific definition required for their Semester 6 exam.
Information Overload: Students drown in unstructured PDFs, audio recordings, and handwritten notes without a unified "Ground Truth."
🟢 The Solution: Context-Aware Intelligence
Syllabus Grounding: Lumen AI anchors every analysis to the official documents uploaded by the user.
Noise Filtering: System prompts instruct the AI to cross-reference spoken words against the syllabus, ignoring irrelevant chatter.
Structured Output: The backend forces a strict JSON schema, ensuring every output (Flashcard, Quiz, Code Snippet) is renderable and reliable.

3. Technical Architecture
3.1 The Tech Stack
Frontend: Flutter (Dart)
Design: Glassmorphism UI (Blur, Neon, Dark Mode).
Rendering: Dynamic JSON-to-Widget generation.
Backend: Python (FastAPI + Asyncio)
Hosting: Render.com (Dockerized Background Worker).
Ingestion Engine: Microsoft MarkItDown (for PDF/PPT/Doc parsing).
AI Models:
Primary: Google Gemini 2.0 Flash (Optimized for speed & multimodal context).
Local Fallback: Ollama + Llama 3 (for privacy-focused, offline text processing).
Database: Supabase (PostgreSQL + Vector Store + Storage).
3.2 The Logic Flow (The "Three-Step" Core)
Ingestion & Vectorization:
User uploads "Ground Truth" (Syllabus/Textbook).
Python backend uses MarkItDown to convert files to clean Markdown.
Data is tagged with metadata (Subject, Module, Unit) and stored in Supabase.
Multimodal Processing:
User records a lecture and selects the context (e.g., Cyber Security -> Unit 2).
The Brain (Backend) combines: Audio File + Syllabus Text + System Instructions.
This composite prompt is sent to Gemini 2.0 Flash.
Response Enforcement:
The AI returns a strict JSON Object.
Flutter parses this JSON to populate the tabs (Summary, Quiz, Mind Map) instantly.

4. Functional Requirements (Features)
🎒 Module A: The Digital Backpack (Context Ingestion)
Syllabus Parsing: Users can upload PDF/DOCX versions of their official curriculum.
Multi-Document Grounding: The system extracts text from diverse formats (PPTs, Reference Books) to build a specific knowledge base for each subject.
Metadata Tagging: All uploaded assets are categorized by Subject (e.g., Mobile App Dev) and Unit/Module (e.g., Unit 3: Firebase) for precise retrieval.
🎙️ Module B: Context-Injected Analysis
Guided Recording: A pre-session setup screen allows users to select the "Unit" the current lecture belongs to.
Benefit: The AI knows exactly what to listen for before the professor speaks.
Smart Noise Filtering: The AI ignores non-academic conversation (e.g., "Assignment deadline is next week," "My dog ate my homework") unless it is tagged as a "Deadline."
📚 Module C: Structured Study Artifacts (The UI)
The app renders the JSON output into 5 dedicated tabs:
1. Exam-Ready Summary
Concise bullet points mapped directly to syllabus keywords.
"Exam Alert" tags for topics the professor emphasized heavily.
2. Interactive Mind Map
Hierarchical visualization of the lecture using the graphview package.
Nodes are tappable to reveal deeper definitions.
3. Active Recall Flashcards
Auto-generated Term/Definition pairs.
Swipe UI (Left/Right) to track retention.
4. The Quiz Engine
Generates 5-10 Multiple Choice Questions (MCQs) based only on the "Ground Truth" material.
Prevents testing on topics the professor hasn't covered yet.
5. The Code Sandbox (New)
Detects if the subject is technical (e.g., Flutter, Python).
Extracts code blocks mentioned in the audio and presents them in a syntax-highlighted window with a "Copy" button.
💬 Module D: The Omniscient Tutor (RAG Chat)
Chat with Notes: Users can query their notes.
Citation Engine: Every answer includes a timestamp link (e.g., [12:40]) linking back to the exact moment in the audio recording.

5. Non-Functional Requirements
Latency: Audio processing for a 1-hour lecture must complete in < 90 seconds (using Gemini Flash).
Reliability: The backend must handle invalid JSON responses from the AI by retrying automatically (Self-Correction).
Scalability: Async processing ensures the app doesn't freeze while uploading large files.

6. Success Metrics (KPIs)
Relevance Score: Percentage of summary points that match the uploaded syllabus keywords.
Reduction Ratio: Compression of a 1-hour audio transcript into a <5 minute read.
Engagement: Average number of follow-up chat questions asked per lecture.

7. Future Scope
LMS Integration: Auto-syncing syllabus from Moodle/Canvas.
Spaced Repetition System (SRS): Algorithm to schedule flashcard reviews based on forgetting curves.
Collaborative Mode: Peer-to-peer sharing of "Lumen Notes" via QR code.
