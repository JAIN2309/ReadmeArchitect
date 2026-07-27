import httpx
from .constants import IMPORTANT_FILES_REGEX
from .utils import parse_owner_repo

async def _fetch_file_content(client: httpx.AsyncClient, owner: str, repo: str, branch: str, path: str, token: str | None = None) -> str:
    url = f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    resp = await client.get(url, headers=headers)
    if resp.status_code == 200:
        return resp.text[:10000] # max 10k chars per file
    return ""

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

async def scrape_repo_structure(github_url: str, token: str | None = None) -> tuple[str, str, str, bool]:
    owner, repo = parse_owner_repo(github_url)
    repo_api = f"https://api.github.com/repos/{owner}/{repo}"
    tree_string = ""
    req_headers = {"Accept": "application/vnd.github.v3+json"}
    if token:
        req_headers["Authorization"] = f"Bearer {token}"

    is_mock = False

    async with httpx.AsyncClient(timeout=30.0) as client:
        repo_resp = await client.get(repo_api, headers=req_headers)
        if repo_resp.status_code != 200:
            return owner, repo, _mock_tree(owner, repo), True

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
            is_mock = True
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

    return owner, repo, meta_block + tree_string, is_mock
