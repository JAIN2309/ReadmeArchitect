from fastapi import APIRouter, HTTPException
import store
from models import HistoryEntry

router = APIRouter()

@router.get("/api/history", response_model=list[HistoryEntry])
async def get_history():
    """Return all past README generations, newest first."""
    return store.get_history()

@router.delete("/api/history/{entry_id}")
async def delete_history_entry(entry_id: int):
    """Delete a single history entry by ID."""
    entry = store.delete_history_entry(entry_id)
    if entry is None:
        raise HTTPException(status_code=404, detail="History entry not found")
    return entry

@router.delete("/api/history")
async def clear_history():
    """Clear all history entries."""
    count = store.clear_history()
    return {"status": "cleared", "deleted_count": count}
