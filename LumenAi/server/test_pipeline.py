"""
Minimal Ollama pipeline test — captures FULL raw output.
"""
import asyncio, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.engine.local_analyzer import LocalAnalyzer

test_content = "Python basics: variables, loops, functions. Assignment due Friday."
test_file = "test_lecture.txt"
with open(test_file, "w", encoding="utf-8") as f:
    f.write(test_content)

async def run():
    analyzer = LocalAnalyzer()
    try:
        result = await analyzer.analyze([test_file], "")
        print(f"\n=== RAW RESULT ({len(result)} chars) ===")
        print(result)  # Print 100% of the output
    except Exception as e:
        print(f"\n❌ EXCEPTION: {type(e).__name__}: {e}")
        import traceback; traceback.print_exc()
    finally:
        if os.path.exists(test_file):
            os.remove(test_file)

asyncio.run(run())
