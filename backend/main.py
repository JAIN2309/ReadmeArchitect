"""
Automated README Architect — FastAPI Backend
=============================================
Scrapes a public GitHub repository's file tree, then uses Google Gemini 2.5 Flash
to generate structured README documentation in one of three presentation modes.
"""

from __future__ import annotations

import os
import re
import time
from datetime import datetime, timezone
from typing import Literal

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from pydantic import BaseModel, field_validator

# ---------------------------------------------------------------------------
# Environment & client bootstrap
# ---------------------------------------------------------------------------
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if not GEMINI_API_KEY:
    raise RuntimeError(
        "GEMINI_API_KEY is not set. "
        "Copy .env.example → .env and add your key from https://aistudio.google.com/apikey"
    )

gemini_client = genai.Client(api_key=GEMINI_API_KEY)

# ---------------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Automated README Architect",
    version="1.0.0",
    description="Generate structured README.md files for any public GitHub repository.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# In-memory history store
# ---------------------------------------------------------------------------

_history: list[HistoryEntry] = []
_next_id: int = 1


# ---------------------------------------------------------------------------
# GitHub repository tree scraper
# ---------------------------------------------------------------------------

IMPORTANT_FILES_REGEX = re.compile(
    r"^(README\.md|package\.json|requirements\.txt|pubspec\.yaml|Dockerfile|docker-compose\.yml|"
    r"tsconfig\.json|pom\.xml|Cargo\.toml|go\.mod|main\.py|src/index\.[jt]sx?|App\.[jt]sx?|lib/main\.dart)$",
    re.IGNORECASE
)

async def _fetch_file_content(client: httpx.AsyncClient, owner: str, repo: str, branch: str, path: str, token: str | None = None) -> str:
    """Fetch raw file content from GitHub and truncate to avoid token limits."""
    url = f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    resp = await client.get(url, headers=headers)
    if resp.status_code == 200:
        return resp.text[:10000] # max 10k chars per file
    return ""

def _parse_owner_repo(github_url: str) -> tuple[str, str]:
    """Extract (owner, repo) from a GitHub URL."""
    parts = github_url.replace("https://", "").replace("http://", "").split("/")
    # parts: ['github.com', 'owner', 'repo', ...]
    if len(parts) < 3:
        raise ValueError("Cannot parse owner/repo from URL.")
    return parts[1], parts[2]


async def scrape_repo_structure(github_url: str, token: str | None = None) -> tuple[str, str, str]:
    """
    Fetch the recursive file tree of a public GitHub repo via the Trees API.

    Returns:
        (owner, repo_name, tree_string)
    """
    owner, repo = _parse_owner_repo(github_url)

    # Step 1 — resolve the default branch SHA via the repo endpoint.
    repo_api = f"https://api.github.com/repos/{owner}/{repo}"
    tree_string = ""
    
    req_headers = {"Accept": "application/vnd.github.v3+json"}
    if token:
        req_headers["Authorization"] = f"Bearer {token}"

    async with httpx.AsyncClient(timeout=30.0) as client:
        repo_resp = await client.get(
            repo_api,
            headers=req_headers,
        )

        if repo_resp.status_code != 200:
            # Fallback: return a mock tree so generation can still proceed.
            return owner, repo, _mock_tree(owner, repo)

        repo_data = repo_resp.json()
        default_branch = repo_data.get("default_branch", "main")
        description = repo_data.get("description", "") or ""
        language = repo_data.get("language", "") or ""
        stars = repo_data.get("stargazers_count", 0)
        license_info = repo_data.get("license", {}) or {}
        license_name = license_info.get("name", "Not specified")

        # Step 2 — fetch the recursive tree.
        tree_api = (
            f"https://api.github.com/repos/{owner}/{repo}"
            f"/git/trees/{default_branch}?recursive=1"
        )
        tree_resp = await client.get(
            tree_api,
            headers=req_headers,
        )

        if tree_resp.status_code == 200:
            tree_data = tree_resp.json()
            entries = tree_data.get("tree", [])
            lines: list[str] = []
            important_paths: list[str] = []
            for entry in entries:
                path = entry["path"]
                kind = "📁" if entry["type"] == "tree" else "📄"
                lines.append(f"{kind} {path}")
                if entry["type"] == "blob" and IMPORTANT_FILES_REGEX.match(path):
                    important_paths.append(path)
            tree_string = "\n".join(lines)
            
            # Fetch up to 5 critical files for deep context
            important_paths = important_paths[:5]
            file_blocks = []
            for path in important_paths:
                content = await _fetch_file_content(client, owner, repo, default_branch, path, token)
                if content:
                    file_blocks.append(f"\n--- FILE: {path} ---\n```\n{content}\n```\n")
            
            tree_string += "\n" + "".join(file_blocks)
        else:
            tree_string = _mock_tree(owner, repo)

    # Prepend repo metadata for richer context.
    meta_block = (
        f"Repository: {owner}/{repo}\n"
        f"Description: {description}\n"
        f"Primary Language: {language}\n"
        f"Stars: {stars}\n"
        f"License: {license_name}\n"
        f"Default Branch: {default_branch}\n"
        f"---\n"
    )

    return owner, repo, meta_block + tree_string


def _mock_tree(owner: str, repo: str) -> str:
    """Fallback mock tree when the GitHub API is unreachable."""
    return (
        f"Repository: {owner}/{repo}\n"
        "---\n"
        "📄 README.md\n"
        "📄 LICENSE\n"
        "📁 src/\n"
        "📄 src/main.py\n"
        "📁 tests/\n"
        "📄 tests/test_main.py\n"
        "📄 requirements.txt\n"
        "📄 .gitignore\n"
    )


# ---------------------------------------------------------------------------
# Presentation-mode prompt templates
# ---------------------------------------------------------------------------

PROMPT_TEMPLATES: dict[PresentationMode, str] = {
    "Basic": (
        "You are a README documentation generator.\n\n"
        "VISUAL LAYOUT STRATEGY:\n"
        "- Use minimalist headers (##) — no deeper than H3.\n"
        "- Provide direct, copy-paste-ready installation command lines.\n"
        "- Write short summary text blocks — no more than 2–3 sentences per section.\n"
        "- Sections to include: Title, One-Line Description, Installation, Usage, License.\n"
        "- Do NOT include badges, contribution guides, or architecture diagrams.\n\n"
        "TARGET AUDIENCE: Small personal utility tools, quick automated scripts.\n\n"
        "Output ONLY the raw Markdown content. Do not wrap it in a code fence."
    ),
    "Advanced": (
        "You are a README documentation generator.\n\n"
        "VISUAL LAYOUT STRATEGY:\n"
        "- Include a clear project title with a one-paragraph description.\n"
        "- Add a 'Features' section as a bulleted list of core system capabilities.\n"
        "- Render an 'Architecture / Folder Structure' section using a plaintext directory tree.\n"
        "- Provide comprehensive 'Getting Started' setup guidelines with prerequisites, "
        "installation steps, and environment configuration.\n"
        "- Include detailed code snippets showing primary usage patterns.\n"
        "- Add sections: Tech Stack, Environment Variables, API Reference (if applicable), "
        "and Roadmap.\n\n"
        "TARGET AUDIENCE: Medium-scale hackathon assets, robust developer portfolio applications.\n\n"
        "Output ONLY the raw Markdown content. Do not wrap it in a code fence."
    ),
    "Professional": (
        "You are a README documentation generator.\n\n"
        "VISUAL LAYOUT STRATEGY:\n"
        "- Start with dynamic shields.io badges for build status, version, license, and "
        "language using proper Markdown image/link syntax.\n"
        "- Include a project logo placeholder: `![Project Logo](assets/logo.png)`.\n"
        "- Use multi-column Markdown tables where appropriate (feature comparison, API "
        "endpoints, environment variables).\n"
        "- Provide visual asset formatting placeholders for screenshots and demo GIFs.\n"
        "- Add a detailed 'Contributing' section with branch naming conventions, PR "
        "templates, code-of-conduct references, and issue labeling standards.\n"
        "- Include a 'License' block with full license text reference.\n"
        "- Include sections: Table of Contents, About The Project, Built With, Getting "
        "Started (Prerequisites, Installation, Configuration), Usage, Roadmap, Contributing, "
        "License, Contact, Acknowledgments.\n\n"
        "TARGET AUDIENCE: Open-source packages, enterprise corporate developer tools.\n\n"
        "Output ONLY the raw Markdown content. Do not wrap it in a code fence."
    ),
}


# ---------------------------------------------------------------------------
# POST /api/auto-readme
# ---------------------------------------------------------------------------

@app.post("/api/auto-readme", response_model=ReadmeResponse)
async def generate_readme(request: ReadmeRequest):
    """
    Accept a public GitHub repository URL and a presentation mode,
    scrape the repo's file tree, and return AI-generated README Markdown.
    """

    # 1 — Scrape repository structure.
    try:
        owner, repo_name, repo_tree = await scrape_repo_structure(
            request.github_url, token=request.github_token
        )
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to scrape repository structure: {exc}",
        )

    # 2 — Select the matching prompt template.
    system_instruction = PROMPT_TEMPLATES[request.presentation_mode]

    # 3 — Build the user message with the repo context.
    user_message = (
        f"Generate a {request.presentation_mode}-tier README.md for the following "
        f"GitHub repository.\n\n"
        f"REPOSITORY CONTEXT (Tree & Key File Contents):\n```\n{repo_tree}\n```\n\n"
        f"Use the repository structure and the source code provided above to perform an in-depth "
        f"analysis of the project's purpose, tech stack, dependencies, and architecture. "
        f"Ensure complete accuracy when referencing code patterns and dependencies. "
        f"Generate a complete, publish-ready README document."
    )

    # 4 — Call Gemini 2.5 Flash with pinned temperature.
    try:
        response = gemini_client.models.generate_content(
            model="gemini-3.5-flash",
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                temperature=0.2,
            ),
        )

        generated_markdown = response.text or ""
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Gemini generation failed: {exc}",
        )

    # 5 — Save to history.
    global _next_id
    entry = HistoryEntry(
        id=_next_id,
        github_url=request.github_url,
        repo_owner=owner,
        repo_name=repo_name,
        presentation_mode=request.presentation_mode,
        markdown=generated_markdown,
        created_at=datetime.now(timezone.utc).isoformat(),
    )
    _history.insert(0, entry)  # newest first
    _next_id += 1

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

@app.get("/api/history", response_model=list[HistoryEntry])
async def get_history():
    """Return all past README generations, newest first."""
    return _history


@app.delete("/api/history/{entry_id}")
async def delete_history_entry(entry_id: int):
    """Delete a single history entry by ID."""
    global _history
    idx = next((i for i, e in enumerate(_history) if e.id == entry_id), None)
    if idx is None:
        raise HTTPException(status_code=404, detail="History entry not found")
    return _history.pop(idx)


# ---------------------------------------------------------------------------
# POST /api/create-pr
# ---------------------------------------------------------------------------

@app.post("/api/create-pr", response_model=PRResponse)
async def create_pr(request: PRRequest):
    """Creates a new branch and opens a PR with the generated README.md"""
    owner, repo = _parse_owner_repo(request.github_url)
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {request.github_token}",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # 1. Get default branch SHA
        repo_resp = await client.get(f"https://api.github.com/repos/{owner}/{repo}", headers=headers)
        if repo_resp.status_code != 200:
            raise HTTPException(400, "Failed to access repo. Is token valid?")
        
        default_branch = repo_resp.json().get("default_branch", "main")
        
        ref_resp = await client.get(f"https://api.github.com/repos/{owner}/{repo}/git/ref/heads/{default_branch}", headers=headers)
        if ref_resp.status_code != 200:
            raise HTTPException(400, "Failed to get branch SHA")
        base_sha = ref_resp.json()["object"]["sha"]
        
        # 2. Create new branch
        new_branch_name = f"readme-architect-update-{int(time.time())}"
        create_ref_resp = await client.post(
            f"https://api.github.com/repos/{owner}/{repo}/git/refs",
            headers=headers,
            json={"ref": f"refs/heads/{new_branch_name}", "sha": base_sha}
        )
        if create_ref_resp.status_code != 201:
            raise HTTPException(400, f"Failed to create branch: {create_ref_resp.text}")
        
        # 3. Get current tree SHA
        commit_resp = await client.get(f"https://api.github.com/repos/{owner}/{repo}/git/commits/{base_sha}", headers=headers)
        tree_sha = commit_resp.json()["tree"]["sha"]
        
        # 4. Create new tree with README.md
        tree_data = {
            "base_tree": tree_sha,
            "tree": [
                {
                    "path": "README.md",
                    "mode": "100644",
                    "type": "blob",
                    "content": request.markdown
                }
            ]
        }
        create_tree_resp = await client.post(
            f"https://api.github.com/repos/{owner}/{repo}/git/trees",
            headers=headers,
            json=tree_data
        )
        new_tree_sha = create_tree_resp.json()["sha"]
        
        # 5. Create commit
        commit_data = {
            "message": "docs: Update README.md via ReadmeArchitect",
            "tree": new_tree_sha,
            "parents": [base_sha]
        }
        create_commit_resp = await client.post(
            f"https://api.github.com/repos/{owner}/{repo}/git/commits",
            headers=headers,
            json=commit_data
        )
        new_commit_sha = create_commit_resp.json()["sha"]
        
        # 6. Update ref
        await client.patch(
            f"https://api.github.com/repos/{owner}/{repo}/git/refs/heads/{new_branch_name}",
            headers=headers,
            json={"sha": new_commit_sha}
        )
        
        # 7. Create PR
        pr_data = {
            "title": "docs: Update README.md",
            "body": "This PR automatically updates the `README.md` file using [ReadmeArchitect](https://github.com/JAIN2309/ReadmeArchitect).\n\n*Review the changes and merge if they look good!*",
            "head": new_branch_name,
            "base": default_branch
        }
        pr_resp = await client.post(
            f"https://api.github.com/repos/{owner}/{repo}/pulls",
            headers=headers,
            json=pr_data
        )
        if pr_resp.status_code != 201:
            raise HTTPException(400, f"Failed to create PR: {pr_resp.text}")
            
        return {"pr_url": pr_resp.json()["html_url"]}


@app.delete("/api/history")
async def clear_history():
    """Clear all history entries."""
    global _history
    count = len(_history)
    _history = []
    return {"status": "cleared", "deleted_count": count}


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "Automated README Architect"}


# ---------------------------------------------------------------------------
# Dev server entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
