from pydantic import BaseModel
from .base import PresentationMode

class HistoryEntry(BaseModel):
    id: int | str | None = None
    github_url: str
    repo_owner: str
    repo_name: str
    presentation_mode: PresentationMode
    markdown: str
    created_at: str
