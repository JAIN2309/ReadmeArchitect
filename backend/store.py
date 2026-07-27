import sqlite3
import json
from contextlib import contextmanager
from models import HistoryEntry

# ---------------------------------------------------------------------------
# SQLite history store
# ---------------------------------------------------------------------------

DB_FILE = "history.db"

def _init_db():
    with sqlite3.connect(DB_FILE) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                github_url TEXT NOT NULL,
                repo_owner TEXT NOT NULL,
                repo_name TEXT NOT NULL,
                presentation_mode TEXT NOT NULL,
                markdown TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
        """)
        conn.commit()

_init_db()

@contextmanager
def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

def get_history(session_id: str) -> list[HistoryEntry]:
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM history WHERE session_id = ? ORDER BY id DESC",
            (session_id,)
        ).fetchall()
        
        entries = []
        for row in rows:
            entries.append(HistoryEntry(
                id=row["id"],
                github_url=row["github_url"],
                repo_owner=row["repo_owner"],
                repo_name=row["repo_name"],
                presentation_mode=row["presentation_mode"],
                markdown=row["markdown"],
                created_at=row["created_at"],
            ))
        return entries

def add_history_entry(session_id: str, entry: HistoryEntry) -> HistoryEntry:
    with get_db() as conn:
        cursor = conn.execute(
            """
            INSERT INTO history (
                session_id, github_url, repo_owner, repo_name, 
                presentation_mode, markdown, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                session_id, entry.github_url, entry.repo_owner, 
                entry.repo_name, entry.presentation_mode, 
                entry.markdown, entry.created_at
            )
        )
        conn.commit()
        entry.id = cursor.lastrowid
        return entry

def delete_history_entry(session_id: str, entry_id: int) -> HistoryEntry | None:
    with get_db() as conn:
        row = conn.execute(
            "SELECT * FROM history WHERE id = ? AND session_id = ?",
            (entry_id, session_id)
        ).fetchone()
        
        if not row:
            return None
            
        conn.execute(
            "DELETE FROM history WHERE id = ? AND session_id = ?",
            (entry_id, session_id)
        )
        conn.commit()
        
        return HistoryEntry(
            id=row["id"],
            github_url=row["github_url"],
            repo_owner=row["repo_owner"],
            repo_name=row["repo_name"],
            presentation_mode=row["presentation_mode"],
            markdown=row["markdown"],
            created_at=row["created_at"],
        )

def clear_history(session_id: str) -> int:
    with get_db() as conn:
        cursor = conn.execute(
            "DELETE FROM history WHERE session_id = ?",
            (session_id,)
        )
        conn.commit()
        return cursor.rowcount
