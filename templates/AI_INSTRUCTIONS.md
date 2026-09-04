# 🤖 AI Assistant Guidelines & Development Rules (Capacitor + Cloud Gradle)

> **Copy and paste this document (or `REPO_ALL_IN_ONE.txt`) into ChatGPT, Claude, Gemini, or Antigravity to get expert assistance building your app.**

---

## 🎯 Role & Objective
You are an expert mobile frontend engineer helping me develop an **offline-first hybrid mobile app** using **Capacitor**. 
This app is automatically built into a native Android APK using **Gradle** inside **GitHub Actions**.

Whenever you write, refactor, or suggest code, you **MUST** strictly follow the 5 Architecture Rules below.

---

## 🛑 The 5 Critical Rules for Capacitor & Gradle Compatibility

### 1. Relative Paths Only (Strict Requirement)
In an Android APK, Capacitor serves code from a local origin (`https://localhost` or `https://appassets.androidplatform.net`). Absolute root paths will fail to load.
* ❌ **NEVER DO THIS:**
  ```html
  <link rel="stylesheet" href="/css/style.css">
  <script src="/js/app.js"></script>
  <img src="/assets/logo.png">
  ```
* ✅ **ALWAYS DO THIS:**
  ```html
  <link rel="stylesheet" href="css/style.css">
  <script src="js/app.js"></script>
  <img src="assets/logo.png">
  ```

### 2. File Organization Hierarchy
All web source code **MUST** reside strictly inside the `src/` directory:
```
src/
├── index.html          # Primary offline entrypoint
├── css/
│   └── style.css       # All styles and layout
├── js/
│   └── app.js          # Client-side JavaScript & Capacitor logic
└── assets/             # Icons, images, audio, fonts
```
* The root `capacitor.config.json` has `"webDir": "src"`.
* Never place client source files outside of `src/`.

### 3. Client-Side Only (No Server-Side Node.js)
* The Android APK runs purely in a mobile WebView. It cannot run Node.js servers, Express backends, or local server files.
* If backend data is required, use `fetch("https://your-api.com/endpoint")` with full HTTPS URLs.
* Ensure offline fallback when `navigator.onLine` is false or the fetch fails.

### 4. Offline-First State & Storage
* The app **must boot and be fully usable without an internet connection**.
* Save all user settings and data locally using:
  * `localStorage` (for light settings and user preferences)
  * `IndexedDB` (for larger offline databases or media caching)
* Detect network changes with `window.addEventListener('online', ...)` and `window.addEventListener('offline', ...)`.

### 5. Mobile Viewport & Touch UX
* Keep the mobile viewport configured in `src/index.html`:
  ```html
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  ```
* Use CSS safe area insets for device notches and system bars:
  ```css
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  ```

---

## ⚙️ How the Cloud Gradle Build Pipeline Works
When changes are pushed to GitHub, `.github/workflows/build-apk.yml`:
1. Launches an Ubuntu cloud runner with Java JDK 17 and Android SDK.
2. Installs `@capacitor/core`, `@capacitor/cli`, and `@capacitor/android`.
3. Runs `npx cap sync android` to copy everything from `src/` into the native Android Gradle project.
4. Compiles the APK with `./gradlew assembleDebug`.
5. Publishes `app-debug.apk` directly to GitHub Actions Artifacts for download.

---

## 💬 Prompt Template to Use with AI
When asking an AI to add a new screen or feature to this repo, paste this prompt:
```text
I am building an offline-first Capacitor mobile app compiled to Android via Gradle.
Please generate code for [FEATURE_NAME].
Follow the rules in AI_INSTRUCTIONS.md:
- Store files in src/ (HTML at src/index.html, styles in src/css/, scripts in src/js/)
- Use relative paths exclusively (e.g. css/style.css, js/app.js)
- Ensure the feature works completely offline with localStorage/IndexedDB
- Provide the exact code blocks with their file paths
```
