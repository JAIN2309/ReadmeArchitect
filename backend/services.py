import os
import re
import time
import httpx
from typing import Tuple
from google import genai
from google.genai import types
from models import PresentationMode

# ---------------------------------------------------------------------------
# Setup Gemini Client
# ---------------------------------------------------------------------------
_gemini_client = None

def get_gemini_client() -> genai.Client:
    global _gemini_client
    if _gemini_client is None:
        api_key = os.getenv("GEMINI_API_KEY", "")
        if not api_key:
            raise RuntimeError(
                "GEMINI_API_KEY is not set. "
                "Copy .env.example → .env and add your key from https://aistudio.google.com/apikey"
            )
        _gemini_client = genai.Client(api_key=api_key)
    return _gemini_client

# ---------------------------------------------------------------------------
# Constants & Prompt Templates
# ---------------------------------------------------------------------------
IMPORTANT_FILES_REGEX = re.compile(
    r"^(README\.md|package\.json|requirements\.txt|pubspec\.yaml|Dockerfile|docker-compose\.yml|"
    r"tsconfig\.json|pom\.xml|Cargo\.toml|go\.mod|main\.py|src/index\.[jt]sx?|App\.[jt]sx?|lib/main\.dart)$",
    re.IGNORECASE
)

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
# GitHub Repository Scraper
# ---------------------------------------------------------------------------

async def _fetch_file_content(client: httpx.AsyncClient, owner: str, repo: str, branch: str, path: str, token: str | None = None) -> str:
    url = f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    resp = await client.get(url, headers=headers)
    if resp.status_code == 200:
        return resp.text[:10000] # max 10k chars per file
    return ""

def _parse_owner_repo(github_url: str) -> tuple[str, str]:
    parts = github_url.replace("https://", "").replace("http://", "").split("/")
    if len(parts) < 3:
        raise ValueError("Cannot parse owner/repo from URL.")
    return parts[1], parts[2]

async def scrape_repo_structure(github_url: str, token: str | None = None) -> tuple[str, str, str]:
    owner, repo = _parse_owner_repo(github_url)
    repo_api = f"https://api.github.com/repos/{owner}/{repo}"
    tree_string = ""
    req_headers = {"Accept": "application/vnd.github.v3+json"}
    if token:
        req_headers["Authorization"] = f"Bearer {token}"

    async with httpx.AsyncClient(timeout=30.0) as client:
        repo_resp = await client.get(repo_api, headers=req_headers)
        if repo_resp.status_code != 200:
            return owner, repo, _mock_tree(owner, repo)

        repo_data = repo_resp.json()
        default_branch = repo_data.get("default_branch", "main")
        description = repo_data.get("description", "") or ""
        language = repo_data.get("language", "") or ""
        stars = repo_data.get("stargazers_count", 0)
        license_info = repo_data.get("license", {}) or {}
        license_name = license_info.get("name", "Not specified")

        tree_api = f"https://api.github.com/repos/{owner}/{repo}/git/trees/{default_branch}?recursive=1"
        tree_resp = await client.get(tree_api, headers=req_headers)

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
            
            important_paths = important_paths[:5]
            file_blocks = []
            for path in important_paths:
                content = await _fetch_file_content(client, owner, repo, default_branch, path, token)
                if content:
                    file_blocks.append(f"\n--- FILE: {path} ---\n```\n{content}\n```\n")
            
            tree_string += "\n" + "".join(file_blocks)
        else:
            tree_string = _mock_tree(owner, repo)

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
# LLM Generation
# ---------------------------------------------------------------------------
def generate_markdown(repo_tree: str, presentation_mode: PresentationMode) -> str:
    client = get_gemini_client()
    system_instruction = PROMPT_TEMPLATES[presentation_mode]
    user_message = (
        f"Generate a {presentation_mode}-tier README.md for the following "
        f"GitHub repository.\n\n"
        f"REPOSITORY CONTEXT (Tree & Key File Contents):\n```\n{repo_tree}\n```\n\n"
        f"Use the repository structure and the source code provided above to perform an in-depth "
        f"analysis of the project's purpose, tech stack, dependencies, and architecture. "
        f"Ensure complete accuracy when referencing code patterns and dependencies. "
        f"Generate a complete, publish-ready README document."
    )
    
    response = client.models.generate_content(
        model="gemini-3.5-flash",
        contents=user_message,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.2,
        ),
    )
    return response.text or ""

# ---------------------------------------------------------------------------
# PR Creation
# ---------------------------------------------------------------------------
async def create_github_pr(github_url: str, github_token: str, markdown: str) -> str:
    owner, repo = _parse_owner_repo(github_url)
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {github_token}",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        repo_resp = await client.get(f"https://api.github.com/repos/{owner}/{repo}", headers=headers)
        if repo_resp.status_code != 200:
            raise Exception("Failed to access repo. Is token valid?")
        
        default_branch = repo_resp.json().get("default_branch", "main")
        
        ref_resp = await client.get(f"https://api.github.com/repos/{owner}/{repo}/git/ref/heads/{default_branch}", headers=headers)
        if ref_resp.status_code != 200:
            raise Exception("Failed to get branch SHA")
        base_sha = ref_resp.json()["object"]["sha"]
        
        new_branch_name = f"readme-architect-update-{int(time.time())}"
        create_ref_resp = await client.post(
            f"https://api.github.com/repos/{owner}/{repo}/git/refs",
            headers=headers,
            json={"ref": f"refs/heads/{new_branch_name}", "sha": base_sha}
        )
        if create_ref_resp.status_code != 201:
            raise Exception(f"Failed to create branch: {create_ref_resp.text}")
        
        commit_resp = await client.get(f"https://api.github.com/repos/{owner}/{repo}/git/commits/{base_sha}", headers=headers)
        tree_sha = commit_resp.json()["tree"]["sha"]
        
        tree_data = {
            "base_tree": tree_sha,
            "tree": [{"path": "README.md", "mode": "100644", "type": "blob", "content": markdown}]
        }
        create_tree_resp = await client.post(
            f"https://api.github.com/repos/{owner}/{repo}/git/trees",
            headers=headers,
            json=tree_data
        )
        new_tree_sha = create_tree_resp.json()["sha"]
        
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
        
        await client.patch(
            f"https://api.github.com/repos/{owner}/{repo}/git/refs/heads/{new_branch_name}",
            headers=headers,
            json={"sha": new_commit_sha}
        )
        
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
            raise Exception(f"Failed to create PR: {pr_resp.text}")
            
        return pr_resp.json()["html_url"]
