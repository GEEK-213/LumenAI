import os
os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'
os.environ['OAUTHLIB_RELAX_TOKEN_SCOPE'] = '1'
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import RedirectResponse
from app.middleware.auth import get_current_user
from pydantic import BaseModel
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import json
import logging
from app.database import supabase
from app.tasks.classroom_sync import manual_sync_subject_classroom
from app.utils.encryption import encrypt_dict, decrypt_dict

router = APIRouter()
logger = logging.getLogger(__name__)

# Google OAuth 2.0 configuration
# NOTE: Requires credentials.json from Google Developer Console
# In production, these should come from environment variables or a secure secret manager
CLIENT_SECRETS_FILE = "credentials.json"

# Classroom & Drive Scopes
SCOPES = [
    'https://www.googleapis.com/auth/classroom.courses.readonly',
    'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
    'https://www.googleapis.com/auth/classroom.courseworkmaterials.readonly',
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/drive.readonly'
]

# Provide a fallback URL for local testing
try:
    with open(CLIENT_SECRETS_FILE, 'r') as f:
        creds_data = json.load(f)
        REDIRECT_URI = creds_data.get('web', {}).get('redirect_uris', ["http://localhost:8001/classroom/oauth/callback"])[-1]
except Exception:
    REDIRECT_URI = "http://localhost:8001/classroom/oauth/callback"

class ClassroomConnectRequest(BaseModel):
    user_id: str

@router.get("/oauth/login")
async def login_google_classroom(user_id: str):
    """
    Step 1: Redirects the user to Google's OAuth 2.0 consent screen.
    """
    if not os.path.exists(CLIENT_SECRETS_FILE):
        return {"error": "Missing credentials.json for Google OAuth. Please configure Google Developer Console."}

    # Use state parameter to securely pass the user_id through the OAuth flow
    flow = Flow.from_client_secrets_file(
        CLIENT_SECRETS_FILE,
        scopes=SCOPES,
        redirect_uri=REDIRECT_URI
    )
    
    authorization_url, state = flow.authorization_url(
        access_type='offline',
        include_granted_scopes='true',
        prompt='consent'
    )
    
    # Store the state locally linked to user_id (In production, use Redis or a DB table)
    # For now, we'll append the user_id to the state to survive the redirect
    custom_state = f"{state}::{user_id}"
    
    authorization_url_with_user = authorization_url.replace(state, custom_state)

    return RedirectResponse(url=authorization_url_with_user)


@router.get("/oauth/callback")
async def oauth_callback(state: str, code: str):
    """
    Step 2: Google redirects back here with an auth code.
    We exchange the code for tokens and save them to Supabase.
    """
    if not os.path.exists(CLIENT_SECRETS_FILE):
        raise HTTPException(status_code=500, detail="Missing credentials.json")

    try:
        # Extract user_id from the mutated state
        original_state, user_id = state.split("::")
        
        flow = Flow.from_client_secrets_file(
            CLIENT_SECRETS_FILE,
            scopes=SCOPES,
            redirect_uri=REDIRECT_URI,
            state=original_state
        )
        
        flow.fetch_token(code=code)
        credentials = flow.credentials

        # Save tokens to Supabase for this user (Encrypted at rest)
        tokens = {
            "token": credentials.token,
            "refresh_token": credentials.refresh_token,
            "token_uri": credentials.token_uri,
            "client_id": credentials.client_id,
            "client_secret": credentials.client_secret,
            "scopes": credentials.scopes
        }
        
        encrypted_tokens = encrypt_dict(tokens)
        
        # Check if row exists
        resp = supabase.table("user_integrations").select("id").eq("user_id", user_id).execute()
        if len(resp.data) > 0:
            supabase.table("user_integrations").update({
                "google_tokens": encrypted_tokens
            }).eq("user_id", user_id).execute()
        else:
            supabase.table("user_integrations").insert({
                "user_id": user_id,
                "google_tokens": encrypted_tokens
            }).execute()

        # Redirect the user back to the app (deep link)
        # Assuming app deep link scheme is lumenai://
        return RedirectResponse(url="lumenai://classroom-success")

    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid state parameter: {e}")
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"OAuth Failed: {e}")

@router.get("/courses")
async def list_courses(user_id: str = Depends(get_current_user)):
    """
    Step 3: Test fetching courses using the saved tokens.
    """
    resp = supabase.table("user_integrations").select("google_tokens").eq("user_id", user_id).single().execute()
    
    if not resp.data or not resp.data.get("google_tokens"):
        raise HTTPException(status_code=401, detail="Google Classroom not connected.")
        
    try:
        if isinstance(resp.data["google_tokens"], str):
            creds_data = decrypt_dict(resp.data["google_tokens"])
        else:
            # Fallback for unencrypted legacy tokens
            creds_data = resp.data["google_tokens"]
    except Exception as e:
        logger.error(f"Failed to decrypt Google tokens: {e}")
        raise HTTPException(status_code=401, detail="Invalid or corrupted Google Classroom tokens.")

    creds = Credentials(
        token=creds_data["token"],
        refresh_token=creds_data["refresh_token"],
        token_uri=creds_data["token_uri"],
        client_id=creds_data["client_id"],
        client_secret=creds_data["client_secret"],
        scopes=creds_data["scopes"]
    )
    
    try:
        service = build('classroom', 'v1', credentials=creds)
        results = service.courses().list(studentId='me', courseStates=['ACTIVE']).execute()
        courses = results.get('courses', [])
        
        return {"status": "success", "courses": courses}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch courses: {e}")

class ManualSyncRequest(BaseModel):
    subject_id: str

@router.post("/sync_subject")
async def sync_subject_manual(req: ManualSyncRequest, user_id: str = Depends(get_current_user)):
    """
    Manually pulls assignments/materials for a given subject if the user has connected Google Classroom.
    """
    try:
        result = await manual_sync_subject_classroom(user_id, req.subject_id)
        return result
    except Exception as e:
        import traceback
        logger.error(f"Manual Sync Failed: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
