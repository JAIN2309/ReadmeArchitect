from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException
import store
import services
from models import ReadmeRequest, ReadmeResponse, HistoryEntry

router = APIRouter()

@router.post("/api/auto-readme", response_model=ReadmeResponse)
async def generate_readme(request: ReadmeRequest):
    """
    Accept a public GitHub repository URL and a presentation mode,
    scrape the repo's file tree, and return AI-generated README Markdown.
    """
    try:
        owner, repo_name, repo_tree = await services.scrape_repo_structure(
            request.github_url, token=request.github_token
        )
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to scrape repository structure: {exc}",
        )

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

    return ReadmeResponse(
        markdown=generated_markdown,
        repo_owner=owner,
        repo_name=repo_name,
        presentation_mode=request.presentation_mode,
    )
