# Mobile Web App (Capacitor + Cloud Gradle Builder)

An offline-first mobile application structured for **Capacitor** with automated **GitHub Actions Gradle APK compilation**.

---

## 🚀 Quick Start & Development

- **Web Source:** All client code lives in `src/`.
- **Offline Entrypoint:** `src/index.html`
- **Styles:** `src/css/style.css`
- **Scripts:** `src/js/app.js`

For full details on the directory hierarchy and architecture decisions, see [FOLDER_ORGANIZATION.md](FOLDER_ORGANIZATION.md).

---

## 🤖 Cloud Gradle APK Compilation

You do **not** need to install heavy Android SDKs or Gradle locally. Every push to the repository automatically triggers the GitHub Actions workflow to build the Android APK.

### Trigger Build Manually (Termux or Terminal)
```bash
gh workflow run build-apk.yml
```

### Download the Compiled APK
```bash
# List recent build runs
gh run list --workflow=build-apk.yml

# Download the latest artifact
gh run download --name app-debug-apk

# (On Android Termux) Move to your storage
mv app-debug.apk /sdcard/Download/
```

---

## 🎨 Custom App Icon Placement
- Place your app icon at: **`assets/icon.png`** (or `icon.png` in root).
- Recommended size: **`512x512 px`** (PNG format).
- **Automated Density Generation:** When GitHub Actions runs, it automatically generates all Android launcher icons (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) including round and adaptive foreground variants, plus Web/PWA icons (`src/icon-192.png`, `src/icon-512.png`).

---

## ⚡ Instant App Launch (Zero Splash Screen Delay)
- By default, Capacitor displays a 3-second splash screen with a popup logo before rendering the app.
- This repository has been pre-configured with **`"launchShowDuration": 0`** and **`"showSpinner": false`** in `capacitor.config.json` and a clean launch drawable.
- The app opens **immediately and smoothly (0ms)** directly into your interface without any loading icon popup or blocking delay.

---

## 🧠 AI Prompt & Codebase Digest

A complete digest of the project with an embedded LLM prompt is available in `<REPO_NAME>_ALL_IN_ONE.txt`. You can pass this file directly into an AI assistant for architecture reviews, feature additions, or debugging.

