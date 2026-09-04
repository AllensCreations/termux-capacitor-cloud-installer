# Project Layout & Architecture Guide (Offline-First Capacitor)

```
.
├── src/                               # 🌐 Web Assets & Application Core (Capacitor webDir)
│   ├── index.html                     # 🎯 Primary offline entry point
│   ├── css/                           # 🎨 Styling & stylesheets (style.css)
│   ├── js/                            # ⚙️ Application logic (app.js)
│   └── assets/                        # 🖼️ Offline icons, images, fonts
│
├── .github/workflows/build-apk.yml    # 🤖 Cloud CI/CD: Gradle APK/AAB build + GitHub Releases
├── capacitor.config.json              # 📱 Capacitor native bridge configuration
├── AI_INSTRUCTIONS.md                 # 🤖 AI assistant prompts & mobile rules
├── GOOGLE_PLAY_STORE_GUIDE.md         # 📱 Google Play requirements & publishing checklist
├── FOLDER_ORGANIZATION.md             # 📖 Architecture & layout blueprint
├── README.md                          # 🚀 Project documentation & APK download guide
└── REPO_ALL_IN_ONE.txt                # 🧠 Consolidated codebase digest with AI prompt
```

---

## 🏗️ Architecture Design Principles

### 1. Dedicated `src/` Web Directory
- **Offline-First Standard:** All client-side runtime files live inside `src/`.
- **Entry Point:** `src/index.html` is served locally by the Capacitor WebView with no external web server dependency required.
- **Dedicated Subfolders:** Stylesheets are strictly grouped in `src/css/` and scripts in `src/js/` to maintain clean separation of concerns.

### 2. Automated Cloud Gradle & GitHub Releases
- Pushing to `main` compiles both `.apk` and `.aab` bundles using Gradle in GitHub Actions cloud runners.
- The build automatically publishes a **GitHub Release** (`v1.0.<run_number>`) where anyone can download the compiled APK directly.
- Read [GOOGLE_PLAY_STORE_GUIDE.md](GOOGLE_PLAY_STORE_GUIDE.md) before publishing to Google Play Console.
