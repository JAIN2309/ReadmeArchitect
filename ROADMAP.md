# 🚀 Automated README Architect — Setup & Run Roadmap

A step-by-step guide to get the full stack running on your machine.

---

## 📋 Prerequisites

Before you begin, make sure you have these installed:

| Tool | Version | Check Command | Install Link |
|------|---------|--------------|--------------|
| **Python** | 3.11+ | `python --version` | [python.org/downloads](https://www.python.org/downloads/) |
| **pip** | Latest | `pip --version` | Bundled with Python |
| **Flutter SDK** | 3.10+ | `flutter --version` | [docs.flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| **Google Chrome** | Latest | — | [google.com/chrome](https://www.google.com/chrome/) |
| **Git** | Any | `git --version` | [git-scm.com](https://git-scm.com/) |
| **Gemini API Key** | — | — | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |

> **Android development** additionally requires Android Studio with an emulator or a physical device with USB debugging enabled.

---

## 🔧 Step 1 — Clone & Navigate

```bash
cd c:\sem-9\gen-ai
```

Your workspace should look like this:

```
gen-ai/
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── mobile_screen.dart
    │   │   └── desktop_screen.dart
    │   ├── services/
    │   │   └── api_service.dart
    │   └── utils/
    │       └── platform_detector.dart
    ├── pubspec.yaml
    └── test/
        └── widget_test.dart
```

---

## 🐍 Step 2 — Backend Setup

### 2.1 Create a virtual environment (recommended)

```bash
cd backend
python -m venv venv

# Windows (PowerShell)
.\venv\Scripts\Activate.ps1

# Windows (CMD)
.\venv\Scripts\activate.bat

# macOS / Linux
source venv/bin/activate
```

### 2.2 Install Python dependencies

```bash
pip install -r requirements.txt
```

This installs: `fastapi`, `uvicorn`, `google-genai`, `pydantic`, `httpx`, `python-dotenv`.

### 2.3 Configure your Gemini API key

```bash
# Copy the template
copy .env.example .env       # Windows
# cp .env.example .env       # macOS/Linux

# Then open .env and replace the placeholder:
# GEMINI_API_KEY=your_actual_key_here
```

> **Get your key** → [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
> (Free tier is sufficient for development.)

### 2.4 Start the backend server

```bash
python main.py
```

You should see:

```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Started reloader process
```

### 2.5 Verify it works

Open your browser and go to:
- **Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Health Check**: [http://localhost:8000/health](http://localhost:8000/health)

You can test the API directly from the Swagger UI by clicking **POST /api/auto-readme** → **Try it out**, then entering:

```json
{
  "github_url": "https://github.com/flutter/flutter",
  "presentation_mode": "Basic"
}
```

> ⚠️ **Keep this terminal running!** The frontend needs the backend alive at `localhost:8000`.

---

## 📱 Step 3 — Frontend Setup

Open a **new terminal** (keep the backend running in the first one).

### 3.1 Install Flutter dependencies

```bash
cd frontend
flutter pub get
```

### 3.2 Run on Chrome (Desktop Web Layout)

```bash
flutter run -d chrome
```

This will:
1. Show the **animated splash screen** (icon entrance → title slide → progress bar → fade transition).
2. Detect Chrome via user-agent → route to the **desktop split-pane dashboard**.
3. Left pane = raw markdown source, Right pane = live rendered preview.

### 3.3 Run on Android (Mobile Layout)

```bash
# List available devices
flutter devices

# Run on a connected device or emulator
flutter run -d <device_id>
```

This routes to the **mobile-optimized single-column layout** with large touch targets.

### 3.4 Run on Edge

```bash
flutter run -d edge
```

Same desktop layout as Chrome — the platform detector identifies both.

---

## 🎯 Step 4 — Using the App

1. **Enter a GitHub URL** in the input field (e.g., `https://github.com/fastapi/fastapi`).
2. **Select a presentation mode**:
   - **Basic** → Minimalist README for small scripts/tools
   - **Advanced** → Feature lists, folder trees, setup guides
   - **Professional** → Badges, tables, contribution guides, license blocks
3. **Click Generate** and wait for the AI to produce the README.
4. **Desktop**: View raw markdown on the left, rendered preview on the right.
5. **Mobile**: Scroll through the rendered markdown output.

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| `GEMINI_API_KEY is not set` | Make sure `.env` exists in `/backend` with your key |
| `Connection refused` on Generate | Ensure the backend is running on port 8000 |
| `Invalid GitHub URL` error | Use the full format: `https://github.com/owner/repo` |
| `flutter run -d chrome` fails | Run `flutter doctor` and ensure Chrome is detected |
| Slow first analysis | Normal — Flutter's first `flutter analyze` builds the cache (~60-90s) |
| CORS errors in browser console | Backend already has `allow_origins=["*"]`; clear browser cache |

---

## 📁 Architecture Summary

```
┌─────────────────────────────────────────────────────┐
│                   Flutter Frontend                   │
│                                                      │
│  main.dart → SplashScreen → PlatformDetector         │
│                    │                                 │
│         ┌─────────┴──────────┐                       │
│         ▼                    ▼                       │
│   MobileScreen         DesktopScreen                 │
│   (Android)         (Chrome / Edge)                  │
│   Single-column     Split-pane layout                │
│                  ┌────────┬────────┐                 │
│                  │Raw MD  │Preview │                 │
│                  └────────┴────────┘                 │
│                                                      │
│          ApiService (POST /api/auto-readme)           │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP
┌──────────────────────▼──────────────────────────────┐
│                  FastAPI Backend                      │
│                                                      │
│  POST /api/auto-readme                               │
│    1. Validate (Pydantic)                            │
│    2. Scrape repo tree (GitHub API)                  │
│    3. Select prompt template (Basic/Advanced/Pro)    │
│    4. Call Gemini 2.5 Flash (temp=0.2)               │
│    5. Return generated markdown                      │
└─────────────────────────────────────────────────────┘
```

---

## 🔮 Next Steps / Enhancements

- [x] ~~Add a **Copy to Clipboard** button for the generated markdown~~ ✅
- [x] ~~Add **Markdown export** (download as `.md` file)~~ ✅
- [x] ~~Add a **history panel** to revisit past generations~~ ✅
- [ ] Support **private repos** via GitHub personal access tokens
- [ ] Deploy backend to **Google Cloud Run** and frontend to **Firebase Hosting**
- [ ] Add **unit tests** for the API endpoint and scraper logic
