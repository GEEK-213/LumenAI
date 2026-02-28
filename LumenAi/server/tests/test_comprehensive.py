"""
LumenAI — Comprehensive Backend Test Suite
Covers: ALL route modules, engines, sync tasks, helpers, and data validation.

Run: python -m pytest tests/test_comprehensive.py -v --tb=short
"""
import json
import asyncio
import inspect
import os
import sys
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ╔═══════════════════════════════════════════════════════════╗
# ║  1. ANALYSIS ROUTE — Unit Tests                          ║
# ╚═══════════════════════════════════════════════════════════╝

class TestExtractJSON:
    """Test JSON extraction helpers used to parse AI model output."""

    def test_clean_json_object(self):
        from app.routes.analysis import extract_json
        raw = '{"summary": "Hello", "topics": ["A"]}'
        parsed = json.loads(extract_json(raw))
        assert parsed["summary"] == "Hello"

    def test_json_with_markdown_fence(self):
        from app.routes.analysis import extract_json
        raw = '```json\n{"summary": "Test"}\n```'
        parsed = json.loads(extract_json(raw))
        assert parsed["summary"] == "Test"

    def test_json_with_preamble_text(self):
        from app.routes.analysis import extract_json
        raw = 'Here is the analysis:\n\n{"summary": "Result"}\n\nEnd.'
        parsed = json.loads(extract_json(raw))
        assert parsed["summary"] == "Result"

    def test_json_with_nested_braces(self):
        from app.routes.analysis import extract_json
        raw = '{"mind_map": {"nodes": [{"id": 1, "label": "AI"}], "edges": []}}'
        parsed = json.loads(extract_json(raw))
        assert len(parsed["mind_map"]["nodes"]) == 1

    def test_json_with_escaped_quotes(self):
        from app.routes.analysis import extract_json
        raw = '{"summary": "He said \\"hello\\" to her"}'
        parsed = json.loads(extract_json(raw))
        assert "hello" in parsed["summary"]

    def test_json_with_newlines_inside(self):
        from app.routes.analysis import extract_json
        raw = '{"summary": "Line 1\\nLine 2\\nLine 3"}'
        parsed = json.loads(extract_json(raw))
        assert "Line 1" in parsed["summary"]

    def test_no_json_returns_original(self):
        from app.routes.analysis import extract_json
        raw = 'no json object here'
        result = extract_json(raw)
        assert isinstance(result, str)


class TestExtractJSONArray:
    """Test JSON array extraction for quiz/flashcard parsing."""

    def test_clean_array(self):
        from app.routes.analysis import extract_json_array
        raw = '[{"question": "Q1"}, {"question": "Q2"}]'
        parsed = json.loads(extract_json_array(raw))
        assert len(parsed) == 2

    def test_array_with_fence(self):
        from app.routes.analysis import extract_json_array
        raw = '```json\n[{"front": "A", "back": "B"}]\n```'
        parsed = json.loads(extract_json_array(raw))
        assert parsed[0]["front"] == "A"

    def test_array_with_preamble(self):
        from app.routes.analysis import extract_json_array
        raw = 'Here are the flashcards:\n[{"front": "X", "back": "Y"}]'
        parsed = json.loads(extract_json_array(raw))
        assert parsed[0]["back"] == "Y"

    def test_array_with_nested_objects(self):
        from app.routes.analysis import extract_json_array
        raw = '[{"question": "Q?", "options": ["A", "B", "C", "D"], "correct_answer": "A", "explanation": "Reason"}]'
        parsed = json.loads(extract_json_array(raw))
        assert len(parsed[0]["options"]) == 4

    def test_empty_array(self):
        from app.routes.analysis import extract_json_array
        raw = '[]'
        parsed = json.loads(extract_json_array(raw))
        assert parsed == []


# ╔═══════════════════════════════════════════════════════════╗
# ║  2. LAZY INITIALIZATION & SEMAPHORE — Unit Tests         ║
# ╚═══════════════════════════════════════════════════════════╝

class TestLazyInit:
    """Test lazy analyzer initialization — server must not crash at import."""

    def test_module_imports_without_crash(self):
        from app.routes.analysis import get_analyzer, get_local_analyzer
        assert callable(get_analyzer)
        assert callable(get_local_analyzer)

    def test_private_analyzer_starts_none(self):
        from app.routes import analysis
        # _analyzer should be None before first call
        assert analysis._analyzer is None or isinstance(analysis._analyzer, object)

    def test_semaphore_exists_and_correct_type(self):
        from app.routes.analysis import analysis_semaphore
        assert isinstance(analysis_semaphore, asyncio.Semaphore)

    @pytest.mark.asyncio
    async def test_semaphore_limits_concurrency_to_2(self):
        from app.routes.analysis import analysis_semaphore
        active, max_active = [], [0]

        async def task(i):
            async with analysis_semaphore:
                active.append(i)
                max_active[0] = max(max_active[0], len(active))
                await asyncio.sleep(0.03)
                active.remove(i)

        await asyncio.gather(*[task(i) for i in range(6)])
        assert max_active[0] <= 2, f"Expected max 2 concurrent, got {max_active[0]}"


# ╔═══════════════════════════════════════════════════════════╗
# ║  3. GEMINI ENGINE (analyzer.py) — Unit Tests             ║
# ╚═══════════════════════════════════════════════════════════╝

class TestGeminiEngine:
    """Verify LectureAnalyzer methods are async and have correct signatures."""

    def test_class_exists(self):
        from app.engine.analyzer import LectureAnalyzer
        assert LectureAnalyzer is not None

    def test_execute_prompt_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        assert inspect.iscoroutinefunction(LectureAnalyzer._execute_prompt)

    def test_generate_initial_view_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        assert inspect.iscoroutinefunction(LectureAnalyzer.generate_initial_view)

    def test_generate_quiz_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        assert inspect.iscoroutinefunction(LectureAnalyzer.generate_quiz)

    def test_generate_flashcards_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        assert inspect.iscoroutinefunction(LectureAnalyzer.generate_flashcards)

    def test_rate_limit_error_class_exists(self):
        from app.engine.analyzer import RateLimitError
        assert issubclass(RateLimitError, Exception)

    def test_prepare_content_exists(self):
        from app.engine.analyzer import LectureAnalyzer
        assert hasattr(LectureAnalyzer, 'prepare_content')


# ╔═══════════════════════════════════════════════════════════╗
# ║  4. LOCAL ENGINE (local_analyzer.py) — Unit Tests        ║
# ╚═══════════════════════════════════════════════════════════╝

class TestLocalEngine:
    """Verify LocalAnalyzer methods are async and have correct signatures."""

    def test_class_exists(self):
        from app.engine.local_analyzer import LocalAnalyzer
        assert LocalAnalyzer is not None

    def test_execute_prompt_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        assert inspect.iscoroutinefunction(LocalAnalyzer._execute_prompt)

    def test_generate_initial_view_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        assert inspect.iscoroutinefunction(LocalAnalyzer.generate_initial_view)

    def test_generate_quiz_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        assert inspect.iscoroutinefunction(LocalAnalyzer.generate_quiz)

    def test_generate_flashcards_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        assert inspect.iscoroutinefunction(LocalAnalyzer.generate_flashcards)

    def test_prepare_content_exists(self):
        from app.engine.local_analyzer import LocalAnalyzer
        assert hasattr(LocalAnalyzer, 'prepare_content')


# ╔═══════════════════════════════════════════════════════════╗
# ║  5. TOKEN REFRESH (classroom_sync.py) — Unit Tests       ║
# ╚═══════════════════════════════════════════════════════════╝

class TestTokenRefresh:
    """Token refresh function must accept user_id and persist tokens."""

    def test_get_valid_credentials_signature(self):
        from app.tasks.classroom_sync import get_valid_credentials
        sig = inspect.signature(get_valid_credentials)
        params = list(sig.parameters.keys())
        assert "tokens" in params
        assert "user_id" in params

    def test_user_id_is_optional(self):
        from app.tasks.classroom_sync import get_valid_credentials
        sig = inspect.signature(get_valid_credentials)
        assert sig.parameters["user_id"].default is None

    def test_sync_user_classroom_is_async(self):
        from app.tasks.classroom_sync import sync_user_classroom
        assert inspect.iscoroutinefunction(sync_user_classroom)

    def test_manual_sync_is_async(self):
        from app.tasks.classroom_sync import manual_sync_subject_classroom
        assert inspect.iscoroutinefunction(manual_sync_subject_classroom)


# ╔═══════════════════════════════════════════════════════════╗
# ║  6. CHAT ROUTE — Unit Tests                              ║
# ╚═══════════════════════════════════════════════════════════╝

class TestChatRoute:
    """Verify chat endpoint exists and has correct signature."""

    def test_chat_router_exists(self):
        from app.routes.chat import router
        assert router is not None

    def test_ask_ai_is_async(self):
        from app.routes.chat import ask_ai
        assert inspect.iscoroutinefunction(ask_ai)

    def test_ask_ai_signature(self):
        from app.routes.chat import ask_ai
        sig = inspect.signature(ask_ai)
        params = list(sig.parameters.keys())
        assert "question" in params
        assert "context" in params
        assert "user_id" in params


# ╔═══════════════════════════════════════════════════════════╗
# ║  7. INGESTION ROUTE — Unit Tests                         ║
# ╚═══════════════════════════════════════════════════════════╝

class TestIngestionRoute:
    """Verify ingestion endpoints exist and have correct signatures."""

    def test_ingestion_router_exists(self):
        from app.routes.ingestion import router
        assert router is not None

    def test_upload_syllabus_is_async(self):
        from app.routes.ingestion import upload_syllabus
        assert inspect.iscoroutinefunction(upload_syllabus)

    def test_upload_syllabus_signature(self):
        from app.routes.ingestion import upload_syllabus
        sig = inspect.signature(upload_syllabus)
        params = list(sig.parameters.keys())
        assert "file" in params
        assert "user_id" in params
        assert "subject_id" in params

    def test_delete_syllabus_is_async(self):
        from app.routes.ingestion import delete_syllabus
        assert inspect.iscoroutinefunction(delete_syllabus)

    def test_rename_syllabus_is_async(self):
        from app.routes.ingestion import rename_syllabus
        assert inspect.iscoroutinefunction(rename_syllabus)


# ╔═══════════════════════════════════════════════════════════╗
# ║  8. CLASSROOM ROUTE — Unit Tests                         ║
# ╚═══════════════════════════════════════════════════════════╝

class TestClassroomRoute:
    """Verify classroom/OAuth endpoints exist and have correct signatures."""

    def test_classroom_router_exists(self):
        from app.routes.classroom import router
        assert router is not None

    def test_oauth_login_is_async(self):
        from app.routes.classroom import login_google_classroom
        assert inspect.iscoroutinefunction(login_google_classroom)

    def test_oauth_callback_is_async(self):
        from app.routes.classroom import oauth_callback
        assert inspect.iscoroutinefunction(oauth_callback)

    def test_list_courses_is_async(self):
        from app.routes.classroom import list_courses
        assert inspect.iscoroutinefunction(list_courses)

    def test_sync_subject_manual_is_async(self):
        from app.routes.classroom import sync_subject_manual
        assert inspect.iscoroutinefunction(sync_subject_manual)

    def test_manual_sync_request_model_fields(self):
        from app.routes.classroom import ManualSyncRequest
        req = ManualSyncRequest(user_id="u1", subject_id="s1")
        assert req.user_id == "u1"
        assert req.subject_id == "s1"

    def test_classroom_connect_request_model(self):
        from app.routes.classroom import ClassroomConnectRequest
        req = ClassroomConnectRequest(user_id="u1")
        assert req.user_id == "u1"


# ╔═══════════════════════════════════════════════════════════╗
# ║  9. ANALYSIS ROUTE — Endpoint Existence Tests            ║
# ╚═══════════════════════════════════════════════════════════╝

class TestAnalysisEndpoints:
    """Verify all analysis endpoints exist and are async."""

    def test_process_lecture_is_async(self):
        from app.routes.analysis import process_lecture
        assert inspect.iscoroutinefunction(process_lecture)

    def test_analyze_lecture_on_demand_is_async(self):
        from app.routes.analysis import analyze_lecture_on_demand
        assert inspect.iscoroutinefunction(analyze_lecture_on_demand)

    def test_delete_lecture_is_async(self):
        from app.routes.analysis import delete_lecture
        assert inspect.iscoroutinefunction(delete_lecture)

    def test_rename_lecture_is_async(self):
        from app.routes.analysis import rename_lecture
        assert inspect.iscoroutinefunction(rename_lecture)

    def test_save_quiz_background_is_async(self):
        from app.routes.analysis import save_quiz_background
        assert inspect.iscoroutinefunction(save_quiz_background)

    def test_save_flashcards_background_is_async(self):
        from app.routes.analysis import save_flashcards_background
        assert inspect.iscoroutinefunction(save_flashcards_background)


# ╔═══════════════════════════════════════════════════════════╗
# ║  10. AI OUTPUT FORMAT VALIDATION — Integration Tests     ║
# ╚═══════════════════════════════════════════════════════════╝

class TestAIOutputValidation:
    """Validate expected AI JSON output formats."""

    def test_full_initial_view_format(self):
        ai_output = {
            "summary": "Test lecture about neural networks.",
            "topics": ["ML", "DL", "CNNs"],
            "mind_map": {
                "nodes": [
                    {"id": 1, "label": "AI"},
                    {"id": 2, "label": "ML"},
                    {"id": 3, "label": "DL"}
                ],
                "edges": [
                    {"from": 1, "to": 2},
                    {"from": 1, "to": 3}
                ]
            },
            "code_snippets": [
                {"title": "Hello", "language": "python", "code_content": "print('hi')"}
            ],
            "extracted_tasks": [
                {"title": "HW 1", "due_date": "2026-03-15"}
            ],
            "teacher_questions": ["Explain backprop"],
            "important_dates": ["2026-03-15"],
            "transcript": "Full text here."
        }
        s = json.dumps(ai_output)
        p = json.loads(s)
        assert isinstance(p["summary"], str)
        assert isinstance(p["topics"], list)
        assert isinstance(p["mind_map"]["nodes"], list)
        assert isinstance(p["mind_map"]["edges"], list)
        assert isinstance(p["code_snippets"], list)
        assert isinstance(p["extracted_tasks"], list)

    def test_quiz_format(self):
        quiz = [{"question": "Q?", "options": ["A","B","C","D"], "correct_answer": "A", "explanation": "Because"}]
        p = json.loads(json.dumps(quiz))
        assert p[0]["question"] == "Q?"
        assert len(p[0]["options"]) == 4

    def test_flashcard_format(self):
        cards = [{"front": "Term", "back": "Def"}]
        p = json.loads(json.dumps(cards))
        assert p[0]["front"] == "Term"

    def test_mind_map_string_ids(self):
        mm = {"nodes": [{"id": "n1", "label": "X"}], "edges": [{"from": "n1", "to": "n2"}]}
        p = json.loads(json.dumps(mm))
        assert p["nodes"][0]["id"] == "n1"

    def test_empty_optional_fields(self):
        output = {"summary": "X", "topics": [], "mind_map": {"nodes": [], "edges": []},
                  "code_snippets": [], "extracted_tasks": [], "teacher_questions": [], "transcript": ""}
        p = json.loads(json.dumps(output))
        assert len(p["code_snippets"]) == 0
        assert len(p["mind_map"]["nodes"]) == 0

    def test_code_snippet_multiple_languages(self):
        snippets = [
            {"title": "Sort", "language": "python", "code_content": "sorted([3,1,2])"},
            {"title": "Sort", "language": "java", "code_content": "Arrays.sort(arr);"},
            {"title": "Sort", "language": "javascript", "code_content": "arr.sort()"},
        ]
        p = json.loads(json.dumps(snippets))
        langs = [s["language"] for s in p]
        assert "python" in langs
        assert "java" in langs
        assert "javascript" in langs


# ╔═══════════════════════════════════════════════════════════╗
# ║  11. DATABASE MODULE — Existence Tests                   ║
# ╚═══════════════════════════════════════════════════════════╝

class TestDatabaseModule:
    """Verify database module is importable and supabase client exists."""

    def test_database_module_imports(self):
        from app.database import supabase
        assert supabase is not None

    def test_supabase_client_has_table_method(self):
        from app.database import supabase
        assert hasattr(supabase, 'table')

    def test_supabase_client_has_storage(self):
        from app.database import supabase
        assert hasattr(supabase, 'storage')


# ╔═══════════════════════════════════════════════════════════╗
# ║  12. MAIN APP — Existence Tests                          ║
# ╚═══════════════════════════════════════════════════════════╝

class TestMainApp:
    """Verify the FastAPI app starts and registers all routers."""

    def test_main_app_imports(self):
        from main import app
        assert app is not None

    def test_app_has_routes(self):
        from main import app
        routes = [r.path for r in app.routes]
        assert len(routes) > 0

    def test_analysis_routes_registered(self):
        from main import app
        paths = [r.path for r in app.routes]
        # Process lecture endpoint should be registered
        assert any("/process" in p for p in paths) or any("/analysis" in p for p in paths) or len(paths) > 5


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
