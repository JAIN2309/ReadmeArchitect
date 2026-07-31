import logging
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Request
from limiter import limiter
import store
import services
from models import ReadmeRequest, ReadmeResponse, HistoryEntry

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

@router.post("/api/auto-readme", response_model=ReadmeResponse)
@limiter.limit("5/minute")
async def generate_readme(request: Request, body: ReadmeRequest):
    """
    Accept a public GitHub repository URL and a presentation mode,
    scrape the repo's file tree, and return AI-generated README Markdown.
    """
    session_id = _get_active_session_id(request)
    try:
        owner, repo_name, repo_tree, is_mock = await services.scrape_repo_structure(
            body.github_url, token=body.github_token
        )
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to scrape repository structure: {exc}",
        )

    try:
        generated_markdown = services.generate_markdown(
            repo_tree=repo_tree, 
            presentation_mode=body.presentation_mode
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Gemini generation failed: {exc}",
        )

    entry = HistoryEntry(
        id=None,
        github_url=body.github_url,
        repo_owner=owner,
        repo_name=repo_name,
        presentation_mode=body.presentation_mode,
        markdown=generated_markdown,
        created_at=datetime.now(timezone.utc).isoformat(),
    )
    store.add_history_entry(session_id, entry)

    return ReadmeResponse(
        markdown=generated_markdown,
        repo_owner=owner,
        repo_name=repo_name,
        presentation_mode=body.presentation_mode,
        is_mock=is_mock,
    )
