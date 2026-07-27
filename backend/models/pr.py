from pydantic import BaseModel

class PRRequest(BaseModel):
    github_url: str
    github_token: str
    markdown: str

class PRResponse(BaseModel):
    pr_url: str
