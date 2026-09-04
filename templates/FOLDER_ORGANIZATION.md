# Project Layout & Architecture Guide (Offline-First Capacitor)

This repository is structured for an **offline-first hybrid mobile application** built using **Capacitor** and compiled into a native Android APK using **Gradle** via GitHub Actions in the cloud.

---

## 📁 Directory Hierarchy

```
.
├── src/                               # 🌐 Web Assets & Application Core (Capacitor webDir)
│   ├── index.html                     # 🎯 Primary offline entry point
│   ├── css/                           # 🎨 Styling & stylesheets
│   │   └── style.css
│   ├── js/                            # ⚙️ Application logic, state & Capacitor plugins
│   │   └── app.js
│   └── assets/                        # 🖼️ Offline icons, images, audio, fonts
│       └── icon.png
│
├── .github/
│   └── workflows/
│       └── build-apk.yml              # 🤖 Cloud CI/CD: Capacitor sync + Gradle APK build
│
├── capacitor.config.json              # 📱 Capacitor native bridge configuration
├── package.json                       # 📦 NPM dependencies & build scripts
├── FOLDER_ORGANIZATION.md             # 📖 This architecture & layout blueprint
├── README.md                          # 🚀 Project documentation & APK download guide
└── REPO_ALL_IN_ONE.txt                # 🧠 Consolidated codebase digest with AI prompt
```

---

## 🏗️ Architecture Design Principles

### 1. Dedicated `src/` Web Directory
- **Offline-First Standard:** All client-side runtime files live inside `src/`.
- **Entry Point:** `src/index.html` is served locally by the Capacitor WebView with no external web server dependency required.
- **Dedicated Subfolders:** Stylesheets are strictly grouped in `src/css/` and scripts in `src/js/` to maintain clean separation of concerns.

### 2. Capacitor Bridge Configuration
- In `capacitor.config.json`, `"webDir": "src"` binds Capacitor directly to the `src/` folder.
- Assets inside `src/` are synchronized into the Android Gradle assets folder (`android/app/src/main/assets/public/`) during build time via `npx cap sync android`.

### 3. Automated Cloud-Based Gradle Build Pipeline
- **Zero Local Footprint:** Neither Java JDK, Android SDK, nor Gradle need to be installed on your development machine or mobile Termux environment.
- When you push changes to `main` (or trigger via GitHub CLI `gh workflow run`), `.github/workflows/build-apk.yml`:
  1. Spins up an Ubuntu cloud runner.
  2. Sets up Java 17 and Android SDK.
  3. Installs Capacitor dependencies.
  4. Scaffolds or updates the Android native Gradle project (`npx cap sync android`).
  5. Compiles the APK with `./gradlew assembleDebug`.
  6. Publishes the ready-to-install `app-debug.apk` directly to GitHub Actions Artifacts.

---

## 📲 Retrieving Your APK (Termux & Mobile Friendly)

You can check and download the built APK directly using GitHub CLI:

```bash
# 1. View recent build status
gh run list --workflow=build-apk.yml

# 2. Download the compiled APK
gh run download <RUN_ID> -n app-debug-apk

# 3. Move APK to your phone's Download folder (if in Termux)
mv app-debug.apk /sdcard/Download/
```
