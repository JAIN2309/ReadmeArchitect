import logging
from fastapi import APIRouter, HTTPException, Request
import store
from models import HistoryEntry

logger = logging.getLogger("uvicorn")
router = APIRouter()

def _get_active_session_id(request: Request) -> str:
    """
    Cryptographically verifies incoming Firebase Bearer ID Tokens if present.
    Resolves the verified User UID (uid), or falls back to X-Session-ID.
    """
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split("Bearer ")[1].strip()
        try:
            import firebase_admin.auth
            decoded_token = firebase_admin.auth.verify_id_token(token)
            verified_uid = decoded_token.get("uid")
            if verified_uid:
                return verified_uid
        except Exception as e:
            logger.warning(f"Bearer Token verification skipped/failed: {e}")

    return request.headers.get("X-Session-ID", "default")

@router.get("/api/history", response_model=list[HistoryEntry])
async def get_history(request: Request):
    """Return all past README generations for the verified session, newest first."""
    session_id = _get_active_session_id(request)
    return store.get_history(session_id)

@router.delete("/api/history/{entry_id}")
async def delete_history_entry(request: Request, entry_id: str):
    """Delete a single history entry by ID."""
    session_id = _get_active_session_id(request)
    entry = store.delete_history_entry(session_id, entry_id)
    if entry is None:
        raise HTTPException(status_code=404, detail="History entry not found")
    return entry

@router.delete("/api/history")
async def clear_history(request: Request):
    """Clear all history entries for the verified session."""
    session_id = _get_active_session_id(request)
    count = store.clear_history(session_id)
    return {"status": "cleared", "deleted_count": count}
