📘Project Lumen –Lecture Analyzer

Project Lumen is a multimodal lecture analysispipeline powered
by**Google** **Gemini**. It ingests lecture assets (audio, video, PDFs,
and documents), cross-references them, and outputs a structured **JSON**
**study** **guide**including summaries, topics,assignments, dates, and
full transcripts.

✨Features

> • Audio & Video transcription (MP3, WAV, MP4, MOV) • Document parsing
> (PDF, DOCX, PPTX, XLSX, TXT)
>
> • Cross-referenced lecture understanding • Clean, strict JSON output
>
> • Automatic retry handling for API limits
>
> • 🗂Tracks already-processed files to avoid duplicates

🔑Requirements

> • Python **3.10+**recommended • Google Gemini API access

📦Required Python Packages Install all required dependencies using pip:

pip install google-genai markitdown python-dotenv

Package Breakdown

Package google-genai markitdown

python-dotenv

Purpose

Gemini SDK (multimodal + JSON output) Converts documents to clean
markdown/text

Loads environment variables from.env

🌍Environment Setup Create a .envfile in the project root:

Gemini_API_key=YOUR_GEMINI_API_KEY_HERE

> Make sure the key has access to **Gemini** **2.0** **models**

📥Supported File Types

Native Gemini Support (Uploadeddirectly)

> • .mp3 • .wav • .mp4 • .mov • .pdf

Text-Converted via MarkItDown

> • .docx • .pptx • .xlsx • .txt

🚀How to Use ️⃣Add Lecture Files Place all lecture assetsinto:

tests/assets/

> Emojis and non-ASCII characters in filenameswill be automatically
> sanitized.

️⃣Run the Analyzer python main.py

️⃣Select Files to Analyze

You’ll see a list like:

--- LUMEN AI: Pending Files ---\[0\] Lecture1.mp4

\[1\] Slides.pdf \[2\] Notes.docx

Choose:-all→ analyze everything-0,2→ analyze specific files

️⃣View Results

Each processed file generates:

processed_results/\<filename\>\_result.json

Processed files are tracked in:

processed_files.json

🧾JSON Output Schema

{

> "summary": "Lecture overview", "topics": \["Topic A", "Topic B"\],
> "tasks": \[
>
> { "task_name": "Homework 1", "due_date": "2026-02-10" } \],
>
> "teacher_questions": \["What is entropy?"\], "important_dates":
> \["2026-02-20"\], "transcript": "Full word-for-word transcript"

}

If no data exists for a field, it returns an empty array (\[\]).
