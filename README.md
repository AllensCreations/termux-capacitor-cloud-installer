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
2. **🚀 Automatic GitHub Releases with Custom Naming:**
   - Every push to `main` compiles both an installable **APK (`.apk`)** and a **Google Play Android App Bundle (`.aab`)** via Gradle.
   - Automatically packages releases with proper naming: **`<RepoName>-<Version>.apk`** (e.g. `MyCoolApp-v1.0.12.apk`), completely eliminating generic `app-debug.apk` naming!
3. **🌐 Instant Live Web Preview (`deploy-pages.yml`):**
   - Automatically deploys `src/` to **GitHub Pages** on every push.
   - Gives you an instant, shareable browser link (`https://<user>.github.io/<repo>/`) to test web features without installing an APK.
4. **🛡️ Mobile WebView Relative Path Guard (`audit-mobile.yml`):**
   - Automatically scans commits for breaking absolute root paths (e.g., `/style.css`) that cause the infamous white blank screen on Android WebViews.
   - Validates JSON config files (`manifest.json`, `capacitor.config.json`).
5. **🎨 Custom App Icon & Automated Density Generation:**
   - Place your custom app icon at `assets/icon.png` (or `icon.png` in root).
   - High-resolution standard: `512x512 px` PNG.
   - Cloud CI automatically generates all Android launcher densities (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`, foreground & round adaptive icons) and PWA icons (`icon-192.png`, `icon-512.png`).
6. **⚡ Instant App Launch (Zero Splash Screen Delay & 0ms Fast):**
   - Eliminates Capacitor's default 3,000ms delay and loading icon popup.
   - Configures `"launchShowDuration": 0`, `"launchFadeOutDuration": 0`, and clean launch drawables so your app boots **immediately and smoothly (0ms)** directly into your UI.
   - **Performance Standard:** "Smooth" means 0ms tap reaction (`touch-action: manipulation`) and instant transitions—not heavy 60fps/120fps animation loops that slow down mobile devices.
7. **🧹 Actions Storage Quota Cleaner (`clean-artifacts.yml`):**
   - Automatically prunes build artifacts older than 14 days to prevent exceeding GitHub's 500MB storage limit.
8. **📱 Google Play Store Publishing Guide (`GOOGLE_PLAY_STORE_GUIDE.md`):**
   - **Account Requirements:** $25 developer account fee, government ID verification, and D-U-N-S business numbers.
   - **Technical Rules:** `.aab` bundle requirements, keystore cryptographic signing, Play App Signing, target API level, incremental `versionCode`, and 200MB size limits.
   - **Store Listing & Policy:** 512x512 icon, 1024x500 feature graphic, screenshots, privacy policy URL, and content ratings.
   - **Closed Testing:** 20 testers for 14 continuous days (for accounts created after Nov 2023).
9. **🤖 AI Assistant Instructions (`AI_INSTRUCTIONS.md`):**
   - Details the strict rules for mobile WebView compatibility (relative paths, `src/` layout, offline storage, safe areas, icon rules).
   - Feed `AI_INSTRUCTIONS.md` or `REPO_ALL_IN_ONE.txt` to ChatGPT, Claude, Gemini, or Antigravity to build app features safely.
10. **🐘 Zero-Setup Cloud Gradle CI (`build-apk.yml`):**
   - Configured with **Java JDK 21 (Temurin)** matching modern Capacitor 6/7 requirements.
   - Built-in **Kotlin duplicate class constraint resolution** (`kotlin-stdlib-jdk8:1.8.22`).
   - Intelligent **dual-path CSS and web asset staging** (`style.css` and `css/style.css`, ES modules, service workers).
   - Builds run 100% in GitHub Actions cloud runners, keeping your device clean of gigabytes of SDKs.

---

## 📲 Downloading Your Release Binaries

### Option 1: Direct Browser Download
Go to your repository's **Releases** tab:
```
https://github.com/<YOUR_USER>/<REPO>/releases
```
Click on `<REPO_NAME>-v1.0.<run_number>.apk` to download directly to your phone.

### Option 2: Termux CLI Download
```bash
# Check workflow runs
gh run list --workflow=build-apk.yml

# Download artifact via gh CLI
gh run download -n app-binaries

# Move APK to your phone storage
mv app-debug.apk /sdcard/Download/
```
