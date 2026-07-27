from __future__ import annotations

import re
from typing import Literal
from pydantic import BaseModel, field_validator

PresentationMode = Literal["Basic", "Advanced", "Professional"]

class ReadmeRequest(BaseModel):
    github_url: str
    presentation_mode: PresentationMode
    github_token: str | None = None

    @field_validator("github_url")
    @classmethod
    def validate_github_url(cls, v: str) -> str:
        pattern = r"^https?://github\.com/[A-Za-z0-9_.\-]+/[A-Za-z0-9_.\-]+/?.*$"
        if not re.match(pattern, v):
            raise ValueError(
                "Invalid GitHub URL. Expected format: https://github.com/owner/repo"
            )
        return v.rstrip("/")

class ReadmeResponse(BaseModel):
    markdown: str
    repo_owner: str
    repo_name: str
    presentation_mode: PresentationMode

class PRRequest(BaseModel):
    github_url: str
    github_token: str
    markdown: str

class PRResponse(BaseModel):
    pr_url: str

class HistoryEntry(BaseModel):
    id: int
    github_url: str
    repo_owner: str
    repo_name: str
    presentation_mode: PresentationMode
    markdown: str
    created_at: str
