# ⚡ Termux Capacitor & Cloud Gradle Workflow Installer

A fully automated, remote installer built for **Android Termux** and Linux terminal environments. It provisions a clean GitHub repository into an **offline-first Capacitor application** equipped with an automated **GitHub Actions Cloud Gradle APK/AAB builder**, **automatic GitHub Releases**, a complete **Google Play Store Publishing Guide**, and a single-file codebase digest with an embedded AI prompt.

---

## 🚀 One-Line Termux Quickstart

Run the installer directly inside **Termux** (or any bash terminal) using `curl`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AllensCreations/termux-capacitor-cloud-installer/main/installer.sh)
```

*(Or clone this repository and run `./installer.sh` locally)*.

---

## 🎯 What the Installer Provides

1. **🌟 Clean New Repo Scaffolding (Recommended):**
   - Automatically creates and configures a brand new repository on your GitHub account.
   - Sets up an offline-first mobile app in `src/` (`index.html`, `css/style.css`, `js/app.js`) with responsive dark mode and offline storage.
2. **🚀 Automatic GitHub Releases:**
   - Every push to `main` compiles both an installable **Debug APK (`.apk`)** and a **Google Play Android App Bundle (`.aab`)** via Gradle.
   - Automatically publishes a **GitHub Release** tagged `v1.0.<run_number>` with direct binary download links!
3. **📱 Google Play Store Publishing Guide (`GOOGLE_PLAY_STORE_GUIDE.md`):**
   - **Account Requirements:** $25 developer account fee, government ID verification, and D-U-N-S business numbers.
   - **Technical Rules:** `.aab` bundle requirements, keystore cryptographic signing, Play App Signing, target API level, incremental `versionCode`, and 200MB size limits.
   - **Store Listing & Policy:** 512x512 icon, 1024x500 feature graphic, screenshots, privacy policy URL, and content ratings.
   - **Closed Testing:** 20 testers for 14 continuous days (for accounts created after Nov 2023).
4. **🤖 AI Assistant Instructions (`AI_INSTRUCTIONS.md`):**
   - Details the 5 strict rules for mobile WebView compatibility (relative paths, `src/` layout, offline storage, safe areas).
   - Feed `AI_INSTRUCTIONS.md` or `REPO_ALL_IN_ONE.txt` to ChatGPT, Claude, Gemini, or Antigravity to build app features safely.
5. **🐘 Zero-Setup Cloud Gradle CI (`build-apk.yml`):**
   - Builds run 100% in GitHub Actions cloud runners.
   - Keeps your phone completely free from gigabytes of heavy Android SDKs and Java Gradle daemons.

---

## 📲 Downloading Your Release Binaries

### Option 1: Direct Browser Download
Go to your repository's **Releases** tab:
```
https://github.com/<YOUR_USER>/<REPO>/releases
```
Click on `app-debug.apk` to download directly to your phone.

### Option 2: Termux CLI Download
```bash
# Check workflow runs
gh run list --workflow=build-apk.yml

# Download artifact via gh CLI
gh run download -n app-binaries

# Move APK to your phone storage
mv app-debug.apk /sdcard/Download/
```
