---

<div align="center">

A **production-grade AI documentation engine** connecting developers with automated, picture-perfect README generation — built with speed, intelligence, and modern design at its core.

<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-005571?style=for-the-badge&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Google_Gemini-2.5_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)

![HTTPX](https://img.shields.io/badge/HTTPX-Async-010101?style=flat-square)
![Pydantic](https://img.shields.io/badge/Pydantic-Validation-E92063?style=flat-square)
![Linear Design](https://img.shields.io/badge/UI/UX-Linear_Inspired-5E5CE6?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

</div>

---

## 📑 Table of Contents
- [✨ Features](#-features)
- [🛠 Tech Stack](#-tech-stack)
- [📂 Project Structure](#-project-structure)
- [🚀 Getting Started](#-getting-started)
- [🧠 AI Architecture](#-ai-architecture)
- [🔌 API Endpoints](#-api-endpoints)
- [⭐ Presentation Modes](#-presentation-modes)

---

## ✨ Features
<table>
<tr>
<td width="33%" valign="top">

### 🤖 AI Engine (Backend)
- **Deep Source Scraping** via GitHub Trees API
- Automatic detection of `package.json`, `main.py`, `pubspec.yaml`, etc.
- **Context-Aware Inference** using Gemini 2.5 Flash
- Pinned temperature (`0.2`) for deterministic markdown output
- Graceful mock-tree fallback for rate limits

</td>
<td width="33%" valign="top">

### 💻 Desktop/Web Frontend
- Sleek, side-by-side **split pane** layout
- Live monospace code editor view
- **Real-time Markdown Renderer** preview
- Smooth shimmer loading animations
- Swipeable **History Sidebar** for past generations
- One-click copy & `.md` download

</td>
<td width="33%" valign="top">

### 📱 Native Mobile Frontend
- Single-column, thumb-friendly vertical scroll
- Beautiful **Onboarding Guide Map** with glowing aesthetics
- Pull-to-refresh & tactile haptic feedback
- "Push to GitHub" Direct PR integration (with Personal Access Tokens)
- Instant fallback copying if downloads aren't supported

</td>
</tr>
</table>

---

<details open>
<summary><b>⚙️ Backend (Python / FastAPI)</b></summary>

| Technology | Purpose |
|-----------|---------|
| **Python 3.11+** | Runtime environment |
| **FastAPI** | High-performance async web framework |
| **Uvicorn** | ASGI server (`--reload` for dev) |
| **Google GenAI SDK** | Direct integration with Gemini 2.5 Flash |
| **HTTPX** | Fully asynchronous HTTP client for GitHub scraping |
| **Pydantic** | Strict data validation and payload serialization |
| **python-dotenv** | Environment variable management |

</details>

<details open>
<summary><b>📱 Frontend (Flutter / Dart)</b></summary>

| Technology | Purpose |
|-----------|---------|
| **Flutter 3.x** | Cross-platform UI toolkit (Web, Desktop, Mobile) |
| **flutter_markdown** | Live rendering of AI-generated markdown strings |
| **shared_preferences** | Secure local storage for GitHub tokens and state |
| **url_launcher** | Triggering downloads and opening Pull Request links |
| **http** | Connecting to the FastAPI backend |
| **Linear-style UI** | Custom built design system (deep `#0A0A0C` colors, glowing borders, smooth fade transitions) |

</details>

---

## 📂 Project Structure

```text
readme_architect/
├── 📁 backend/
│   ├── main.py                # FastAPI server, Gemini client, & GitHub Scraper
│   ├── requirements.txt       # Python dependencies
│   └── .env.example           # Environment template (Needs GEMINI_API_KEY)
│
└── 📁 frontend/
    ├── lib/
    │   ├── main.dart                 # App entry point, Theme config
    │   ├── models/history_entry.dart # Data models
    │   ├── screens/
    │   │   ├── splash_screen.dart      # Animated startup logo
    │   │   ├── onboarding_screen.dart  # 4-step interactive guide map
    │   │   ├── desktop_screen.dart     # Side-by-side web/desktop view
    │   │   └── mobile_screen.dart      # Vertical mobile view
    │   ├── services/
    │   │   ├── api_service.dart        # HTTP client to backend
    │   │   └── export_service.dart     # Web download / Clipboard logic
    │   ├── utils/platform_detector.dart# Responsive routing logic
    │   └── widgets/history_panel.dart  # Slide-out past generations list
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites
> [Flutter SDK](https://docs.flutter.dev/get-started/install) · [Python 3.11+](https://www.python.org/downloads/) · Google Gemini API Key

### 1️⃣ Clone the repository
```bash
git clone https://github.com/JAIN2309/ReadmeArchitect.git
cd ReadmeArchitect
```

### 2️⃣ Backend Setup
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
GEMINI_API_KEY=your_gemini_api_key_here
```
> 💡 **Get a Key:** Generate one for free at [Google AI Studio](https://aistudio.google.com/app/apikey).

Start the backend server:
```bash
uvicorn main:app --reload --port 8000
```

### 3️⃣ Frontend Setup
Open a new terminal window and navigate to the frontend directory:
```bash
cd frontend
flutter pub get
```

Run the application on Desktop Web (Chrome):
```bash
flutter run -d chrome
```

---

## 🧠 AI Architecture

The engine doesn't just guess what your project does based on the name. It actively scrapes the source code.

```text
┌─────────────────────────────┐   ┌──────────────────────────────────────────┐
│  1️⃣ GitHub Scraper           │   │  2️⃣ Gemini 2.5 Flash Inference           │
│     Fetches Default Branch   │   │     Analyzes tech stack & dependencies   │
│     Pulls recursive file tree│ ─→│     Applies specific "Presentation Mode" │
│     Downloads top 5 files    │   │     Returns structured raw Markdown      │
└─────────────────────────────┘   └──────────────────────────────────────────┘
```

By passing files like `package.json` or `requirements.txt` straight into the LLM context window, the AI can document exact setup commands and architectural decisions without hallucinations.

---

## ⭐ Presentation Modes

| Mode | Target Audience | Formatting Strategy |
|-------|------|-------------|
| **Basic** | Small utility scripts | Minimalist H3 headers, direct copy-paste install commands, short sentences. |
| **Advanced** | Hackathons / Portfolios | Adds Features list, directory tree visualization, detailed tech stack, API references. |
| **Professional** | Enterprise / Open Source | Injects Shields.io badges, Markdown tables, contributing guidelines, license blocks, and logo placeholders. |

---

<div align="center">

## 👤 Author
**Krish Jain**

[![GitHub](https://img.shields.io/badge/GitHub-@JAIN2309-181717?style=for-the-badge&logo=github)](https://github.com/JAIN2309)
[![Email](https://img.shields.io/badge/Email-krishjain641@gmail.com-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:krishjain641@gmail.com)
[![Repo](https://img.shields.io/badge/Repo-ReadmeArchitect-2088FF?style=for-the-badge&logo=git)](https://github.com/JAIN2309/ReadmeArchitect)

<br/>

*Architecting the future of documentation.* 📝

</div>
