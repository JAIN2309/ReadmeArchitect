from models import HistoryEntry

# ---------------------------------------------------------------------------
# In-memory history store
# ---------------------------------------------------------------------------

_history: list[HistoryEntry] = []
_next_id: int = 1

def get_history() -> list[HistoryEntry]:
    return _history

def add_history_entry(entry: HistoryEntry):
    global _next_id
    _history.insert(0, entry)
    _next_id += 1

def delete_history_entry(entry_id: int) -> HistoryEntry | None:
    global _history
    idx = next((i for i, e in enumerate(_history) if e.id == entry_id), None)
    if idx is None:
        return None
    return _history.pop(idx)

def clear_history() -> int:
    global _history
    count = len(_history)
    _history = []
    return count

def get_next_id() -> int:
    return _next_id
