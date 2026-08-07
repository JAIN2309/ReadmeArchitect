import os
import json
import sqlite3
import logging
from contextlib import contextmanager
from models import HistoryEntry

logger = logging.getLogger("uvicorn")

# ---------------------------------------------------------------------------
# Firebase Cloud Firestore Store with SQLite Fallback
# ---------------------------------------------------------------------------

_firestore_db = None

def _init_firebase():
    global _firestore_db
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        if not firebase_admin._apps:
            service_account_env = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
            service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "firebase_service_account.json")

            cred = None
            if service_account_env:
                cred_dict = json.loads(service_account_env)
                cred = credentials.Certificate(cred_dict)
            elif os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)

            if cred:
                firebase_admin.initialize_app(cred)
                _firestore_db = firestore.client()
                logger.info("Firebase Cloud Firestore initialized successfully.")
            else:
                logger.info("No Firebase Service Account credentials found. Falling back to SQLite.")
        else:
            from firebase_admin import firestore
            _firestore_db = firestore.client()
    except Exception as e:
        logger.warning(f"Firebase initialization skipped ({e}). Falling back to SQLite.")

_init_firebase()

# ---------------------------------------------------------------------------
# SQLite Fallback Engine
# ---------------------------------------------------------------------------

DB_FILE = "history.db"

def _init_sqlite():
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

_init_sqlite()

@contextmanager
def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

# ---------------------------------------------------------------------------
# Unified Public Storage API
# ---------------------------------------------------------------------------

def get_history(session_id: str) -> list[HistoryEntry]:
    if _firestore_db:
        try:
            user_history_ref = _firestore_db.collection("users").document(session_id).collection("history")
            docs = list(user_history_ref.stream())
            entries = []
            for doc in docs:
                data = doc.to_dict()
                entries.append(HistoryEntry(
                    id=doc.id,
                    github_url=data.get("github_url", ""),
                    repo_owner=data.get("repo_owner", ""),
                    repo_name=data.get("repo_name", ""),
                    presentation_mode=data.get("presentation_mode", "Basic"),
                    markdown=data.get("markdown", ""),
                    created_at=data.get("created_at", ""),
                ))
            # Sort by creation date descending in memory to avoid Firestore index errors
            entries.sort(key=lambda x: x.created_at, reverse=True)
            return entries
        except Exception as e:
            logger.error(f"Firestore get_history error: {e}. Falling back to SQLite.")

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
    if _firestore_db:
        try:
            user_history_ref = _firestore_db.collection("users").document(session_id).collection("history")
            data = {
                "github_url": entry.github_url,
                "repo_owner": entry.repo_owner,
                "repo_name": entry.repo_name,
                "presentation_mode": str(entry.presentation_mode),
                "markdown": entry.markdown,
                "created_at": entry.created_at,
            }
            _, doc_ref = user_history_ref.add(data)
            entry.id = doc_ref.id
            logger.info(f"Successfully added history entry {doc_ref.id} to Firestore for user {session_id}.")
            return entry
        except Exception as e:
            logger.error(f"Firestore add_history_entry error: {e}. Falling back to SQLite.")

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
                entry.repo_name, str(entry.presentation_mode), 
                entry.markdown, entry.created_at
            )
        )
        conn.commit()
        entry.id = cursor.lastrowid
        return entry

def delete_history_entry(session_id: str, entry_id: str | int) -> HistoryEntry | None:
    if _firestore_db:
        try:
            doc_ref = _firestore_db.collection("users").document(session_id).collection("history").document(str(entry_id))
            doc = doc_ref.get()
            if doc.exists:
                data = doc.to_dict()
                entry = HistoryEntry(
                    id=doc.id,
                    github_url=data.get("github_url", ""),
                    repo_owner=data.get("repo_owner", ""),
                    repo_name=data.get("repo_name", ""),
                    presentation_mode=data.get("presentation_mode", "Basic"),
                    markdown=data.get("markdown", ""),
                    created_at=data.get("created_at", ""),
                )
                doc_ref.delete()
                return entry
        except Exception as e:
            logger.error(f"Firestore delete_history_entry error: {e}. Falling back to SQLite.")

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
    if _firestore_db:
        try:
            user_history_ref = _firestore_db.collection("users").document(session_id).collection("history")
            docs = user_history_ref.stream()
            count = 0
            for doc in docs:
                doc.reference.delete()
                count += 1
            return count
        except Exception as e:
            logger.error(f"Firestore clear_history error: {e}. Falling back to SQLite.")

    with get_db() as conn:
        cursor = conn.execute(
            "DELETE FROM history WHERE session_id = ?",
            (session_id,)
        )
        conn.commit()
        return cursor.rowcount
