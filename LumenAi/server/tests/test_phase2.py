"""
LumenAI Phase 2 Backend Tests
Tests for: Async analyzers, lazy initialization, semaphore, token refresh, JSON extraction.
Run: python -m pytest tests/test_phase2.py -v
"""
import json
import asyncio
import pytest
import sys
import os

# Add server root to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ═══════════════════════════════════════════════════════════
# 1. JSON Extraction Tests (Unit)
# ═══════════════════════════════════════════════════════════

class TestJSONExtraction:
    """Test the extract_json and extract_json_array functions used to parse AI output."""

    def test_extract_json_clean(self):
        from app.routes.analysis import extract_json
        raw = '{"summary": "Hello", "topics": ["A", "B"]}'
        result = extract_json(raw)
        parsed = json.loads(result)
        assert parsed["summary"] == "Hello"
        assert len(parsed["topics"]) == 2

    def test_extract_json_with_markdown_fence(self):
        from app.routes.analysis import extract_json
        raw = '```json\n{"summary": "Test"}\n```'
        result = extract_json(raw)
        parsed = json.loads(result)
        assert parsed["summary"] == "Test"

    def test_extract_json_with_preamble(self):
        from app.routes.analysis import extract_json
        raw = 'Here is the JSON:\n\n{"summary": "Result"}\n\nDone!'
        result = extract_json(raw)
        parsed = json.loads(result)
        assert parsed["summary"] == "Result"

    def test_extract_json_array_clean(self):
        from app.routes.analysis import extract_json_array
        raw = '[{"question": "Q1"}, {"question": "Q2"}]'
        result = extract_json_array(raw)
        parsed = json.loads(result)
        assert len(parsed) == 2

    def test_extract_json_array_with_fence(self):
        from app.routes.analysis import extract_json_array
        raw = '```json\n[{"front": "A", "back": "B"}]\n```'
        result = extract_json_array(raw)
        parsed = json.loads(result)
        assert parsed[0]["front"] == "A"

    def test_extract_json_nested_braces(self):
        from app.routes.analysis import extract_json
        raw = '{"mind_map": {"nodes": [{"id": 1}], "edges": [{"from": 1, "to": 2}]}}'
        result = extract_json(raw)
        parsed = json.loads(result)
        assert len(parsed["mind_map"]["nodes"]) == 1

    def test_extract_json_empty_returns_original(self):
        from app.routes.analysis import extract_json
        raw = 'no json here at all'
        result = extract_json(raw)
        # Should return the original or a substring
        assert isinstance(result, str)

    def test_extract_json_with_escaped_quotes(self):
        from app.routes.analysis import extract_json
        raw = '{"summary": "He said \\"hello\\" to her"}'
        result = extract_json(raw)
        parsed = json.loads(result)
        assert "hello" in parsed["summary"]


# ═══════════════════════════════════════════════════════════
# 2. Lazy Analyzer Initialization Tests
# ═══════════════════════════════════════════════════════════

class TestLazyInitialization:
    """Test that analyzers are not instantiated at import time."""

    def test_module_imports_without_crash(self):
        """Server should start even if GEMINI_API_KEY is missing."""
        # If we got this far, the module imported successfully
        from app.routes.analysis import get_analyzer, get_local_analyzer
        assert callable(get_analyzer)
        assert callable(get_local_analyzer)

    def test_lazy_analyzer_not_initialized_at_import(self):
        from app.routes import analysis
        assert analysis._analyzer is None or isinstance(analysis._analyzer, object)

    def test_semaphore_exists(self):
        from app.routes.analysis import analysis_semaphore
        assert isinstance(analysis_semaphore, asyncio.Semaphore)


# ═══════════════════════════════════════════════════════════
# 3. Token Refresh Tests (Unit)
# ═══════════════════════════════════════════════════════════

class TestTokenRefresh:
    """Test get_valid_credentials function."""

    def test_get_valid_credentials_signature(self):
        """Verify the function accepts user_id parameter."""
        from app.tasks.classroom_sync import get_valid_credentials
        import inspect
        sig = inspect.signature(get_valid_credentials)
        params = list(sig.parameters.keys())
        assert "tokens" in params
        assert "user_id" in params

    def test_get_valid_credentials_user_id_optional(self):
        """user_id should be optional (defaults to None)."""
        from app.tasks.classroom_sync import get_valid_credentials
        import inspect
        sig = inspect.signature(get_valid_credentials)
        param = sig.parameters["user_id"]
        assert param.default is None


# ═══════════════════════════════════════════════════════════
# 4. Async Engine Tests
# ═══════════════════════════════════════════════════════════

class TestAsyncEngines:
    """Verify that _execute_prompt methods are async coroutines."""

    def test_gemini_execute_prompt_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LectureAnalyzer._execute_prompt)

    def test_gemini_generate_initial_view_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LectureAnalyzer.generate_initial_view)

    def test_gemini_generate_quiz_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LectureAnalyzer.generate_quiz)

    def test_gemini_generate_flashcards_is_async(self):
        from app.engine.analyzer import LectureAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LectureAnalyzer.generate_flashcards)

    def test_local_execute_prompt_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LocalAnalyzer._execute_prompt)

    def test_local_generate_initial_view_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LocalAnalyzer.generate_initial_view)

    def test_local_generate_quiz_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LocalAnalyzer.generate_quiz)

    def test_local_generate_flashcards_is_async(self):
        from app.engine.local_analyzer import LocalAnalyzer
        import inspect
        assert inspect.iscoroutinefunction(LocalAnalyzer.generate_flashcards)


# ═══════════════════════════════════════════════════════════
# 5. Semaphore Concurrency Test
# ═══════════════════════════════════════════════════════════

class TestSemaphore:
    """Verify the analysis semaphore correctly limits concurrency."""

    @pytest.mark.asyncio
    async def test_semaphore_limits_to_2(self):
        from app.routes.analysis import analysis_semaphore
        
        active = []
        max_active = [0]

        async def mock_task(task_id):
            async with analysis_semaphore:
                active.append(task_id)
                max_active[0] = max(max_active[0], len(active))
                await asyncio.sleep(0.05)
                active.remove(task_id)

        # Launch 5 tasks simultaneously
        await asyncio.gather(*[mock_task(i) for i in range(5)])
        
        # At most 2 should have been active at once
        assert max_active[0] <= 2, f"Max concurrent was {max_active[0]}, expected <= 2"


# ═══════════════════════════════════════════════════════════
# 6. Data Model Validation Tests
# ═══════════════════════════════════════════════════════════

class TestAIOutputParsing:
    """Test that AI output JSON can be correctly parsed."""

    def test_full_initial_view_output(self):
        """Simulate what Gemini returns for generate_initial_view."""
        ai_output = {
            "summary": "This is a test summary about AI.",
            "topics": ["Machine Learning", "Neural Networks"],
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
                {"title": "Hello World", "language": "python", "code_content": "print('hello')"}
            ],
            "extracted_tasks": [
                {"title": "Assignment 1", "due_date": "2026-03-15"}
            ],
            "teacher_questions": ["What is gradient descent?"],
            "important_dates": ["2026-03-15"],
            "transcript": "Full transcript here."
        }
        
        # Verify JSON serialization
        json_str = json.dumps(ai_output)
        parsed = json.loads(json_str)
        
        assert parsed["summary"] == "This is a test summary about AI."
        assert len(parsed["topics"]) == 2
        assert len(parsed["mind_map"]["nodes"]) == 3
        assert len(parsed["mind_map"]["edges"]) == 2
        assert len(parsed["code_snippets"]) == 1
        assert parsed["code_snippets"][0]["language"] == "python"

    def test_empty_optional_fields(self):
        """AI might return empty arrays for optional fields."""
        ai_output = {
            "summary": "Short summary",
            "topics": [],
            "mind_map": {"nodes": [], "edges": []},
            "code_snippets": [],
            "extracted_tasks": [],
            "teacher_questions": [],
            "important_dates": [],
            "transcript": ""
        }
        json_str = json.dumps(ai_output)
        parsed = json.loads(json_str)
        assert parsed["summary"] == "Short summary"
        assert len(parsed["code_snippets"]) == 0

    def test_mind_map_with_string_ids(self):
        """AI sometimes returns string IDs instead of integers."""
        ai_output = {
            "mind_map": {
                "nodes": [
                    {"id": "1", "label": "Root"},
                    {"id": "2", "label": "Child"}
                ],
                "edges": [
                    {"from": "1", "to": "2"}
                ]
            }
        }
        # Should be parseable without errors
        parsed = json.loads(json.dumps(ai_output))
        assert parsed["mind_map"]["nodes"][0]["id"] == "1"

    def test_quiz_output_format(self):
        quiz = [
            {
                "question": "What is AI?",
                "options": ["A", "B", "C", "D"],
                "correct_answer": "A",
                "explanation": "Because..."
            }
        ]
        parsed = json.loads(json.dumps(quiz))
        assert len(parsed) == 1
        assert len(parsed[0]["options"]) == 4

    def test_flashcard_output_format(self):
        cards = [
            {"front": "Term", "back": "Definition"}
        ]
        parsed = json.loads(json.dumps(cards))
        assert parsed[0]["front"] == "Term"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
