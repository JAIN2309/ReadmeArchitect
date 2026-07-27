def parse_owner_repo(github_url: str) -> tuple[str, str]:
    parts = github_url.replace("https://", "").replace("http://", "").split("/")
    if len(parts) < 3:
        raise ValueError("Cannot parse owner/repo from URL.")
    return parts[1], parts[2]
