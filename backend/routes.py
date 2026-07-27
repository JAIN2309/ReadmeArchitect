from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException
import store
import services
from models import (
    ReadmeRequest, 
    ReadmeResponse, 
    PRRequest, 
    PRResponse, 
    HistoryEntry
)

router = APIRouter()

# ---------------------------------------------------------------------------
# POST /api/auto-readme
# ---------------------------------------------------------------------------

@router.post("/api/auto-readme", response_model=ReadmeResponse)
async def generate_readme(request: ReadmeRequest):
    """
    Accept a public GitHub repository URL and a presentation mode,
    scrape the repo's file tree, and return AI-generated README Markdown.
    """
    # 1 — Scrape repository structure.
    try:
        owner, repo_name, repo_tree = await services.scrape_repo_structure(
            request.github_url, token=request.github_token
        )
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to scrape repository structure: {exc}",
        )

    # 2 & 3 & 4 — Generate markdown using Gemini
    try:
        generated_markdown = services.generate_markdown(
            repo_tree=repo_tree, 
            presentation_mode=request.presentation_mode
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Gemini generation failed: {exc}",
        )

    # 5 — Save to history.
    entry = HistoryEntry(
        id=store.get_next_id(),
        github_url=request.github_url,
        repo_owner=owner,
        repo_name=repo_name,
        presentation_mode=request.presentation_mode,
        markdown=generated_markdown,
        created_at=datetime.now(timezone.utc).isoformat(),
    )
    store.add_history_entry(entry)

    # 6 — Return structured response.
    return ReadmeResponse(
        markdown=generated_markdown,
        repo_owner=owner,
        repo_name=repo_name,
        presentation_mode=request.presentation_mode,
    )

# ---------------------------------------------------------------------------
# History endpoints
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# POST /api/create-pr
# ---------------------------------------------------------------------------

@router.post("/api/create-pr", response_model=PRResponse)
async def create_pr(request: PRRequest):
    """Creates a new branch and opens a PR with the generated README.md"""
    try:
        pr_url = await services.create_github_pr(
            github_url=request.github_url,
            github_token=request.github_token,
            markdown=request.markdown
        )
        return {"pr_url": pr_url}
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))
