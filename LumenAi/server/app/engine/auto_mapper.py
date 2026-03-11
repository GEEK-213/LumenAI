"""
Smart Syllabus Auto-Mapper Engine
Uses Gemini to match unmapped lectures to the best-fitting unit
based on syllabus content similarity.
"""

import json
import logging
from google import genai
from google.genai import types
from app.config import Config
from app.database import supabase

logger = logging.getLogger(__name__)

AUTO_MAP_PROMPT = """You are an academic content classifier. Given a lecture transcript/summary and a list of course units with their syllabus descriptions, determine which unit the lecture belongs to.

LECTURE CONTENT:
{lecture_content}

AVAILABLE UNITS:
{units_descriptions}

Respond ONLY with valid JSON:
{{
  "unit_id": "<the UUID of the best matching unit>",
  "unit_name": "<name of the matched unit>",
  "confidence": <float between 0.0 and 1.0>,
  "reason": "<one sentence explaining why this unit is the best match>"
}}

If no unit is a reasonable match (confidence < 0.3), respond with:
{{
  "unit_id": null,
  "unit_name": null,
  "confidence": 0.0,
  "reason": "No unit matches the lecture content."
}}
"""


async def auto_map_lecture(lecture_id: str, subject_id: str, transcript: str, summary: str = ""):
    """
    Core auto-mapping function.
    1. Fetches all units + syllabus text for the subject
    2. Asks Gemini which unit best matches
    3. Updates the lecture row and logs the suggestion
    """
    logger.info(f"🗺️ Auto-mapping lecture {lecture_id} to a unit in subject {subject_id}")

    try:
        # 1. Fetch all units for this subject
        units_res = supabase.table("units").select("id, name, unit_number").eq("subject_id", subject_id).order("unit_number").execute()
        units = units_res.data or []

        if not units:
            logger.info(f"  ⚠️ No units found for subject {subject_id}. Skipping auto-map.")
            return None

        # 2. Fetch syllabus text for each unit
        unit_descriptions = []
        for unit in units:
            syllabus_res = supabase.table("syllabus_sources") \
                .select("extracted_text") \
                .eq("unit_id", unit["id"]) \
                .execute()

            syllabus_text = ""
            for row in (syllabus_res.data or []):
                if row.get("extracted_text"):
                    syllabus_text += row["extracted_text"][:2000] + "\n"

            unit_descriptions.append(
                f"UNIT ID: {unit['id']}\n"
                f"UNIT NAME: {unit['name']}\n"
                f"UNIT NUMBER: {unit.get('unit_number', 'N/A')}\n"
                f"SYLLABUS CONTENT: {syllabus_text[:3000] if syllabus_text else 'No syllabus uploaded yet.'}\n"
                f"---"
            )

        # 3. Build lecture content (use transcript first, fallback to summary)
        lecture_content = transcript[:8000] if transcript else (summary[:8000] if summary else "")
        if not lecture_content:
            logger.info("  ⚠️ Lecture has no transcript or summary. Skipping auto-map.")
            return None

        # 4. Call Gemini
        prompt = AUTO_MAP_PROMPT.format(
            lecture_content=lecture_content,
            units_descriptions="\n\n".join(unit_descriptions)
        )

        client = genai.Client(api_key=Config.GEMINI_API_KEY)
        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[prompt],
            config=types.GenerateContentConfig(
                temperature=0.1,  # Low temp for deterministic classification
                max_output_tokens=500,
            )
        )

        result_text = response.text.strip()

        # Clean markdown fences if present
        if result_text.startswith("```"):
            result_text = result_text.split("\n", 1)[1] if "\n" in result_text else result_text[3:]
        if result_text.endswith("```"):
            result_text = result_text[:-3]
        result_text = result_text.strip()

        data = json.loads(result_text)
        suggested_unit_id = data.get("unit_id")
        confidence = data.get("confidence", 0.0)
        reason = data.get("reason", "")
        unit_name = data.get("unit_name", "")

        logger.info(f"  🎯 Auto-map result: {unit_name} (confidence: {confidence})")

        # 5. Log the suggestion
        supabase.table("auto_map_log").insert({
            "lecture_id": lecture_id,
            "suggested_unit_id": suggested_unit_id,
            "confidence": confidence,
            "reason": reason,
            "accepted": False,
        }).execute()

        # 6. Auto-apply if high confidence (>= 0.7)
        if suggested_unit_id and confidence >= 0.7:
            supabase.table("lectures").update({
                "unit_id": suggested_unit_id,
            }).eq("id", lecture_id).execute()

            # Mark as accepted in log
            supabase.table("auto_map_log").update({
                "accepted": True,
            }).eq("lecture_id", lecture_id).eq("suggested_unit_id", suggested_unit_id).execute()

            logger.info(f"  ✅ Auto-applied: lecture {lecture_id} → unit {unit_name}")

        return {
            "unit_id": suggested_unit_id,
            "unit_name": unit_name,
            "confidence": confidence,
            "reason": reason,
            "auto_applied": suggested_unit_id is not None and confidence >= 0.7,
        }

    except Exception as e:
        logger.error(f"  ❌ Auto-map failed for lecture {lecture_id}: {e}")
        import traceback
        traceback.print_exc()
        return None


async def get_mapping_suggestion(lecture_id: str) -> dict | None:
    """
    On-demand: fetch or generate a mapping suggestion for a lecture.
    First checks if a suggestion already exists in auto_map_log,
    otherwise triggers a fresh mapping.
    """
    # Check existing suggestion
    log_res = supabase.table("auto_map_log") \
        .select("*") \
        .eq("lecture_id", lecture_id) \
        .order("created_at", desc=True) \
        .limit(1) \
        .execute()

    if log_res.data:
        row = log_res.data[0]
        # Fetch unit name
        unit_name = None
        if row.get("suggested_unit_id"):
            unit_res = supabase.table("units").select("name").eq("id", row["suggested_unit_id"]).execute()
            if unit_res.data:
                unit_name = unit_res.data[0]["name"]

        return {
            "unit_id": row.get("suggested_unit_id"),
            "unit_name": unit_name,
            "confidence": row.get("confidence", 0),
            "reason": row.get("reason", ""),
            "accepted": row.get("accepted", False),
        }

    # No existing suggestion — trigger fresh mapping
    lecture_res = supabase.table("lectures") \
        .select("subject_id, transcript, summary") \
        .eq("id", lecture_id) \
        .execute()

    if not lecture_res.data:
        return None

    lecture = lecture_res.data[0]
    return await auto_map_lecture(
        lecture_id=lecture_id,
        subject_id=lecture["subject_id"],
        transcript=lecture.get("transcript", ""),
        summary=lecture.get("summary", ""),
    )
