# ReadmeArchitect

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Google_Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Gemini" />
</div>

<br />

**ReadmeArchitect** is an intelligent full-stack application designed to automatically generate picture-perfect, in-depth Markdown documentation for any public GitHub repository. Instead of just guessing based on file names, the engine performs deep contextual analysis on actual repository source code (dependencies, configuration, and entry points) to write highly accurate, publish-ready README files.

## ✨ Features

- **Deep Source Analysis**: Scrapes up to 5 critical files (e.g. `package.json`, `requirements.txt`, `main.py`) directly from GitHub for absolute tech stack accuracy.
- **Three Presentation Modes**: Generate documentation in Basic, Advanced, or Professional formats depending on your project size.
- **Premium UI/UX**: Built with a sleek, minimalist "Linear-style" design system featuring an interactive onboarding guide map and a live markdown preview.
- **Instant Export**: Copy your generated markdown straight to the clipboard or download it as a `.md` file.
- **Local History**: Revisit your past AI generations instantly from the built-in history panel.

## 🏗️ Architecture (Monorepo)

This project uses a decoupled monorepo structure:
- **/frontend**: A cross-platform Flutter application (Mobile & Desktop Web) that handles the UI, presentation, and markdown rendering.
- **/backend**: A high-performance Python FastAPI server that handles GitHub scraping and Google Gemini API inference asynchronously.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Python 3.11+](https://www.python.org/downloads/)
- Google Gemini API Key

### 1. Backend Setup (FastAPI)
Navigate to the backend directory and set up the Python environment:
```bash
cd backend
python -m venv venv

# Windows
.\venv\Scripts\activate
# Mac/Linux
source venv/bin/activate

pip install -r requirements.txt
```

Create a `.env` file in the `backend/` directory:
```env
GEMINI_API_KEY=your_api_key_here
```

Start the backend server:
```bash
uvicorn main:app --reload --port 8000
```

### 2. Frontend Setup (Flutter)
Open a new terminal window and navigate to the frontend directory:
```bash
cd frontend
flutter pub get
flutter run -d chrome  # Run on Desktop Web
# OR
flutter run            # Run on a connected mobile device/emulator
```

## 👨‍💻 Author

**Krish Jain**
- GitHub: [@JAIN2309](https://github.com/JAIN2309)
- Email: krishjain641@gmail.com
