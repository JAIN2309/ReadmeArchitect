import re
from models import PresentationMode

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
