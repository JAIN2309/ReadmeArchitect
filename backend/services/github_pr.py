import time
import httpx
from .utils import parse_owner_repo

async def create_github_pr(github_url: str, github_token: str, markdown: str) -> str:
    owner, repo = parse_owner_repo(github_url)
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
