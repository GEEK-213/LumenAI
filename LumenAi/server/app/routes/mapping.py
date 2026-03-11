"""
Mapping Routes — Smart Syllabus Auto-Mapping API
Provides endpoints for fetching, applying, and reviewing auto-map suggestions.
"""

import logging
from fastapi import APIRouter, HTTPException, Depends, Form
from app.database import supabase
from app.middleware.auth import get_current_user
from app.engine.auto_mapper import get_mapping_suggestion, auto_map_lecture

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/suggest/{lecture_id}")
async def suggest_mapping(lecture_id: str, user_id: str = Depends(get_current_user)):
    """
    Get an auto-mapping suggestion for an unmapped lecture.
    Returns the best matching unit with confidence + reasoning.
    """
    try:
        result = await get_mapping_suggestion(lecture_id)
        if result is None:
            return {"status": "no_suggestion", "message": "Could not generate a mapping suggestion."}
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"❌ Error getting mapping suggestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/apply/{lecture_id}")
async def apply_mapping(
    lecture_id: str,
    unit_id: str = Form(...),
    user_id: str = Depends(get_current_user),
):
    """
    Manually apply a unit mapping to a lecture.
    Used when the user accepts the AI suggestion or picks a unit manually.
    """
    try:
        # Update lecture row
        supabase.table("lectures").update({
            "unit_id": unit_id,
        }).eq("id", lecture_id).execute()

        # Mark as accepted in log (if an entry exists)
        supabase.table("auto_map_log").update({
            "accepted": True,
        }).eq("lecture_id", lecture_id).execute()

        return {"status": "success", "message": "Mapping applied successfully."}
    except Exception as e:
        logger.error(f"❌ Error applying mapping: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/log/{lecture_id}")
async def get_mapping_log(lecture_id: str, user_id: str = Depends(get_current_user)):
    """
    Returns the auto-mapping history for a lecture.
    """
    try:
        log_res = supabase.table("auto_map_log") \
            .select("*") \
            .eq("lecture_id", lecture_id) \
            .order("created_at", desc=True) \
            .execute()

        return {"status": "success", "data": log_res.data or []}
    except Exception as e:
        logger.error(f"❌ Error fetching mapping log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/remap/{lecture_id}")
async def remap_lecture(lecture_id: str, user_id: str = Depends(get_current_user)):
    """
    Force a fresh auto-mapping attempt (ignores cached suggestions).
    """
    try:
        lecture_res = supabase.table("lectures") \
            .select("subject_id, transcript, summary") \
            .eq("id", lecture_id) \
            .execute()

        if not lecture_res.data:
            raise HTTPException(status_code=404, detail="Lecture not found.")

        lecture = lecture_res.data[0]
        result = await auto_map_lecture(
            lecture_id=lecture_id,
            subject_id=lecture["subject_id"],
            transcript=lecture.get("transcript", ""),
            summary=lecture.get("summary", ""),
        )

        if result is None:
            return {"status": "no_suggestion", "message": "Could not generate a mapping."}
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"❌ Error remapping lecture: {e}")
        raise HTTPException(status_code=500, detail=str(e))
