from fastapi import APIRouter, HTTPException, Request
import store
from models import HistoryEntry

router = APIRouter()

@router.get("/api/history", response_model=list[HistoryEntry])
async def get_history(request: Request):
    """Return all past README generations, newest first."""
    session_id = request.headers.get("X-Session-ID", "default")
    return store.get_history(session_id)

@router.delete("/api/history/{entry_id}")
async def delete_history_entry(request: Request, entry_id: int):
    """Delete a single history entry by ID."""
    session_id = request.headers.get("X-Session-ID", "default")
    entry = store.delete_history_entry(session_id, entry_id)
    if entry is None:
        raise HTTPException(status_code=404, detail="History entry not found")
    return entry

@router.delete("/api/history")
async def clear_history(request: Request):
    """Clear all history entries."""
    session_id = request.headers.get("X-Session-ID", "default")
    count = store.clear_history(session_id)
    return {"status": "cleared", "deleted_count": count}
