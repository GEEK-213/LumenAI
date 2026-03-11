import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.database import supabase
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

res = supabase.table("user_integrations").select("user_id, google_tokens").limit(1).execute()
if res.data:
    tokens = res.data[0]['google_tokens']
    creds = Credentials(
        token=tokens["token"],
        refresh_token=tokens.get("refresh_token"),
        token_uri=tokens.get("token_uri", "https://oauth2.googleapis.com/token"),
        client_id=tokens["client_id"],
        client_secret=tokens["client_secret"],
        scopes=tokens["scopes"]
    )
    classroom_service = build('classroom', 'v1', credentials=creds)
    courses = classroom_service.courses().list(studentId='me', courseStates=['ACTIVE']).execute().get('courses', [])
    if courses:
        course_id = courses[0]['id']
        cw_results = classroom_service.courses().courseWork().list(courseId=course_id).execute()
        course_works = cw_results.get('courseWork', [])
        for cw in course_works:
            print("CourseWork:", cw.get("title"))
            materials = cw.get('materials', [])
            for material in materials:
                if 'driveFile' in material:
                    drive_file = material['driveFile']['driveFile']
                    print("  Found Drive File:", drive_file.get('title'), drive_file.get('id'))
                    file_id = drive_file.get('id')
                    try:
                        drive_service = build('drive', 'v3', credentials=creds)
                        # Try to get metadata first
                        file_meta = drive_service.files().get(fileId=file_id).execute()
                        print("    Drive meta success!", file_meta)
                        break
                    except Exception as e:
                        print("    Drive meta error:", e)
            if materials:
                break
