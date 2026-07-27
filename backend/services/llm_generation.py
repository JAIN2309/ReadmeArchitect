from google.genai import types
from models import PresentationMode
from .constants import PROMPT_TEMPLATES
from .gemini import get_gemini_client

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
