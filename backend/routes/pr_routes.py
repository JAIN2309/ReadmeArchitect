from fastapi import APIRouter, HTTPException
import services
from models import PRRequest, PRResponse

router = APIRouter()

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
