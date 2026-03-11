import asyncio
import os
import json
from datetime import datetime
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
import logging
import difflib

from app.database import supabase
from app.utils.encryption import encrypt_dict, decrypt_dict

logger = logging.getLogger(__name__)


def get_valid_credentials(tokens: dict, user_id: str = None) -> Credentials:
    """
    Build Google credentials from stored tokens.
    Automatically refreshes if the access token has expired.
    Persists refreshed tokens back to Supabase to avoid repeated refreshes.
    """
    creds = Credentials(
        token=tokens["token"],
        refresh_token=tokens.get("refresh_token"),
        token_uri=tokens.get("token_uri", "https://oauth2.googleapis.com/token"),
        client_id=tokens["client_id"],
        client_secret=tokens["client_secret"],
        scopes=tokens["scopes"]
    )
    
    # Refresh if expired
    if creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
            print("🔄 Google OAuth token refreshed successfully.")
            
            # Persist the new token back to Supabase
            if user_id:
                updated_tokens = {
                    **tokens,
                    "token": creds.token,
                }
                try:
                    encrypted_updated = encrypt_dict(updated_tokens)
                    supabase.table("user_integrations").update({
                        "google_tokens": encrypted_updated
                    }).eq("user_id", user_id).execute()
                    print("💾 Refreshed token saved to Supabase.")
                except Exception as save_err:
                    print(f"⚠️ Could not persist refreshed token: {save_err}")
        except Exception as e:
            print(f"⚠️ Token refresh failed: {e}")
    
    return creds

async def start_classroom_sync_job():
    """
    Background worker that runs periodically (e.g., every 6 hours)
    to fetch new assignments from Google Classroom and inject them into 
    the student's extracted_tasks table in Supabase.
    """
    while True:
        try:
            logger.info("Starting Google Classroom Sync Job...")
            res = supabase.table("user_integrations").select("user_id, google_tokens").execute()
            
            for row in res.data:
                user_id = row['user_id']
                raw_tokens = row.get('google_tokens')
                if not raw_tokens:
                    continue
                
                try:
                    if isinstance(raw_tokens, str):
                        tokens = decrypt_dict(raw_tokens)
                    else:
                        tokens = raw_tokens
                except Exception:
                    logger.warning(f"Failed to decrypt token for user {user_id}")
                    continue
                    
                await sync_user_classroom(user_id, tokens)
                
            logger.info("Classroom Sync complete. Sleeping for 6 hours.")
        except Exception as e:
            logger.error(f"Error during overall classroom sync: {e}")
            
        # Run every 6 hours
        await asyncio.sleep(60 * 60 * 6)


async def get_matching_subject(user_id: str, course_name: str):
    res = supabase.table("subjects").select("id, name").eq("user_id", user_id).execute()
    if not res.data:
        return None
    
    course_lower = course_name.lower()
    best_match = None
    best_ratio = 0.0
    
    for row in res.data:
        subj_lower = row['name'].lower()
        if subj_lower in course_lower or course_lower in subj_lower:
            return row['id']
            
        ratio = difflib.SequenceMatcher(None, subj_lower, course_lower).ratio()
        if ratio > best_ratio:
            best_ratio = ratio
            best_match = row['id']
            
    if best_ratio > 0.75:
        return best_match
    return None

async def process_classroom_attachment(user_id: str, subject_id: str, file_id: str, file_title: str):
    """
    Saves a Google Drive file reference as an UN-ANALYZED lecture.
    No file download or AI processing happens here.
    The file is re-downloaded on-demand when the user taps 'Make it Smart'.
    """
    # Check if already exists (by drive_file_id to avoid duplicates even if renamed)
    existing = supabase.table("lectures").select("id").eq("user_id", user_id).eq("drive_file_id", file_id).execute()
    if existing.data:
        print(f"    ⏭️ Already exists: '{file_title}', skipping.")
        return

    # Check for allowed file extensions
    suffix = os.path.splitext(file_title)[1].lower()
    allowed_extensions = ['.pdf', '.doc', '.docx', '.ppt', '.pptx', '.txt']
    if suffix and suffix not in allowed_extensions:
        print(f"    ⏭️ Skipping {file_title}: unsupported file type '{suffix}'")
        return
    
    # Save as un-analyzed lecture (NO download, NO AI processing)
    lecture_data = {
        "user_id": user_id,
        "subject_id": subject_id,
        "title": file_title,
        "summary": "",
        "transcript": "",
        "raw_analysis": None,
        "drive_file_id": file_id,
        "is_analyzed": False,
    }
    
    try:
        res = supabase.table("lectures").insert(lecture_data).execute()
        lecture_id = res.data[0]['id']
        print(f"    ✅ Saved un-analyzed lecture: '{file_title}' (id: {lecture_id})")
    except Exception as e:
        print(f"    ❌ Failed to save lecture '{file_title}': {e}")


async def sync_user_classroom(user_id: str, tokens: dict):
    try:
        creds = get_valid_credentials(tokens, user_id=user_id)
        
        service = build('classroom', 'v1', credentials=creds)
        calendar_service = build('calendar', 'v3', credentials=creds)
        
        results = service.courses().list(studentId='me', courseStates=['ACTIVE']).execute()
        courses = results.get('courses', [])
        
        for course in courses:
            course_id = course['id']
            course_name = course['name']
            subject_id = await get_matching_subject(user_id, course_name)
            
            # Fetch CourseWork
            cw_results = service.courses().courseWork().list(courseId=course_id).execute()
            course_works = cw_results.get('courseWork', [])
            
            for cw in course_works:
                title = cw.get('title')
                dueDate = cw.get('dueDate')
                dueTime = cw.get('dueTime')
                
                # Auto-sync ONLY extracts due dates — no file downloads
                # File downloads happen on-demand via "Pull from Classroom" button

                if dueDate and title:
                    year = dueDate.get('year', datetime.now().year)
                    month = dueDate.get('month', 1)
                    day = dueDate.get('day', 1)
                    hour = dueTime.get('hours', 23) if dueTime else 23
                    minute = dueTime.get('minutes', 59) if dueTime else 59
                    
                    due_date_dt = datetime(year, month, day, hour, minute)
                    due_date_iso = due_date_dt.isoformat() + "Z"
                    
                    existing = supabase.table("extracted_tasks").select("id").eq("user_id", user_id).eq("title", title).execute()
                    
                    if not existing.data:
                        supabase.table("extracted_tasks").insert({
                            "user_id": user_id, "title": title, "due_date": due_date_iso, "is_completed": False
                        }).execute()
                        
                        try:
                            event = {
                                'summary': f"📚 Due: {title}",
                                'description': 'Auto-imported from Google Classroom via LumenAI.',
                                'start': {'dateTime': due_date_iso},
                                'end': {'dateTime': due_date_iso},
                                'reminders': {
                                    'useDefault': False,
                                    'overrides': [
                                        {'method': 'popup', 'minutes': 60},
                                        {'method': 'popup', 'minutes': 24 * 60},
                                    ],
                                },
                            }
                            calendar_service.events().insert(calendarId='primary', body=event).execute()
                            logger.info(f"Pushed {title} to Google Calendar.")
                        except Exception as e:
                            logger.error(f"Failed to push to Google Calendar: {e}")

            # Auto-sync intentionally skips courseWorkMaterials.
            # File downloads happen on-demand via "Pull from Classroom" button.

    except Exception as e:
        logger.error(f"Failed to sync Classroom for user {user_id}: {e}")

async def manual_sync_subject_classroom(user_id: str, subject_id: str):
    print(f"\n{'='*60}")
    print(f"🔄 MANUAL SYNC STARTED for subject_id: {subject_id}")
    print(f"{'='*60}")
    
    res = supabase.table("subjects").select("name").eq("id", subject_id).execute()
    if not res.data:
        print(f"❌ Subject ID '{subject_id}' NOT FOUND in subjects table!")
        raise Exception("Subject not found in database.")
    subject_name = res.data[0]["name"]
    print(f"✅ Subject found: '{subject_name}'")

    res = supabase.table("user_integrations").select("google_tokens").eq("user_id", user_id).execute()
    if not res.data or not res.data[0].get("google_tokens"):
        print(f"❌ No Google tokens for user {user_id}")
        raise Exception("Google Classroom not connected.")
    print(f"✅ Google tokens found for user")
    
    raw_tokens = res.data[0]["google_tokens"]
    try:
        if isinstance(raw_tokens, str):
            tokens = decrypt_dict(raw_tokens)
        else:
            tokens = raw_tokens
    except Exception:
        raise Exception("Failed to decrypt tokens. Re-connect Google Classroom.")
        
    creds = get_valid_credentials(tokens, user_id=user_id)
    
    service = build('classroom', 'v1', credentials=creds)
    
    results = service.courses().list(studentId='me', courseStates=['ACTIVE']).execute()
    courses = results.get('courses', [])
    
    print(f"\n📚 Google Classroom courses found: {len(courses)}")
    for i, c in enumerate(courses):
        print(f"  [{i+1}] {c['name']} (id: {c['id']})")
    
    target_course_id = None
    course_lower = subject_name.lower()
    best_match_id = None
    best_ratio = 0.0
    
    print(f"\n🔍 Searching for match to: '{course_lower}'")
    for course in courses:
        c_name = course['name'].lower()
        if course_lower in c_name or c_name in course_lower:
            target_course_id = course['id']
            print(f"  ✅ SUBSTRING MATCH: '{c_name}' contains '{course_lower}'")
            break
            
        ratio = difflib.SequenceMatcher(None, course_lower, c_name).ratio()
        print(f"  ❓ '{c_name}' ratio: {ratio:.3f}")
        if ratio > best_ratio:
            best_ratio = ratio
            best_match_id = course['id']
            
    if not target_course_id:
        if best_ratio > 0.75:
            target_course_id = best_match_id
            print(f"  ✅ FUZZY MATCH selected with ratio: {best_ratio:.3f}")
        else:
            print(f"  ❌ NO MATCH FOUND. Best ratio was {best_ratio:.3f} (< 0.75)")
            raise Exception(f"No matching Google Classroom course found for subject: {subject_name}")
    
    print(f"\n🎯 Matched course ID: {target_course_id}")
        
    materials_found = 0
    try:
        cw_results = service.courses().courseWork().list(courseId=target_course_id).execute()
        all_cw = cw_results.get('courseWork', [])
        print(f"\n📝 CourseWork items found: {len(all_cw)}")
        
        for cw in all_cw:
            cw_title = cw.get('title', 'Untitled')
            cw_type = cw.get('workType', 'UNKNOWN')
            materials = cw.get('materials', [])
            print(f"  📝 '{cw_title}' | Type: {cw_type} | Attachments: {len(materials)}")
            
            for material in materials:
                mat_types = list(material.keys())
                
                if 'driveFile' in material:
                    drive_file = material['driveFile']['driveFile']
                    file_title = drive_file.get('title', 'Unknown')
                    file_id = drive_file.get('id')
                    print(f"    📎 DriveFile: '{file_title}' (id: {file_id})")
                    await process_classroom_attachment(user_id, subject_id, file_id, file_title)
                    materials_found += 1
                elif 'link' in material:
                    print(f"    🔗 Link (skipped): {material['link'].get('url', 'N/A')}")
                elif 'youtubeVideo' in material:
                    print(f"    ▶️ YouTube (skipped)")
                elif 'form' in material:
                    print(f"    📋 Google Form (skipped)")
                else:
                    print(f"    ❓ Unknown type: {mat_types}")
                    
        print(f"\n{'='*60}")
        print(f"✅ SYNC COMPLETE. Drive files attempted: {materials_found}")
        print(f"{'='*60}\n")
    except Exception as e:
        print(f"❌ Error during courseWork fetch: {e}")
        import traceback
        traceback.print_exc()

    # Fetch CourseWorkMaterials (professor-posted notes, experiments, unit PDFs)
    print(f"\n📂 Fetching courseWorkMaterials...")
    try:
        cwm_results = service.courses().courseWorkMaterials().list(courseId=target_course_id).execute()
        all_cwm = cwm_results.get('courseWorkMaterial', [])
        print(f"📂 CourseWorkMaterials found: {len(all_cwm)}")
        
        for cwm in all_cwm:
            cwm_title = cwm.get('title', 'Untitled')
            cwm_materials = cwm.get('materials', [])
            print(f"  📄 '{cwm_title}' | Attachments: {len(cwm_materials)}")
            
            for material in cwm_materials:
                if 'driveFile' in material:
                    drive_file = material['driveFile']['driveFile']
                    file_title = drive_file.get('title', 'Unknown')
                    file_id = drive_file.get('id')
                    print(f"    📎 DriveFile: '{file_title}' (id: {file_id})")
                    await process_classroom_attachment(user_id, subject_id, file_id, file_title)
                    materials_found += 1
                elif 'link' in material:
                    print(f"    🔗 Link (skipped): {material['link'].get('url', 'N/A')}")
                elif 'youtubeVideo' in material:
                    print(f"    ▶️ YouTube (skipped)")
                else:
                    print(f"    ❓ Other type: {list(material.keys())}")
    except Exception as e:
        print(f"❌ Error fetching courseWorkMaterials: {e}")
        import traceback
        traceback.print_exc()

    print(f"\n{'='*60}")
    print(f"✅ TOTAL SYNC COMPLETE. Drive files attempted: {materials_found}")
    print(f"{'='*60}\n")
        
    return {"status": "success", "processed_attachments": materials_found}

