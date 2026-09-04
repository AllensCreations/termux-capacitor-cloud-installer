# 🤖 AI Assistant Guidelines & Development Rules (Capacitor + Cloud Gradle)

> **Feed this file (or `REPO_ALL_IN_ONE.txt`) to ChatGPT, Claude, Gemini, or Antigravity to build features with 100% Capacitor, Gradle & Google Play compatibility.**

---

## 🎯 System Role & Architecture Constraints
You are an expert mobile developer and project organizer. Review the provided repository files and develop the application following a clean, minimal, and scalable offline-first Capacitor architecture.

### 🛑 5 Strict Rules for Capacitor & Gradle Compatibility:
1. **Relative Paths Exclusively:**
   - Inside WebView, files load from `https://localhost` or `https://appassets.androidplatform.net`.
   - Never use absolute root paths (`/css/style.css`, `/js/app.js`).
   - ALWAYS use relative paths (`css/style.css`, `js/app.js`, `./assets/icon.png`).
2. **Dedicated `src/` Layout:**
   - All client files MUST live in `src/` (`src/index.html`, `src/css/`, `src/js/`, `src/assets/`).
   - `capacitor.config.json` targets `"webDir": "src"`.
3. **Client-Side Only (No Node.js Runtime):**
   - The APK runs purely in a mobile WebView.
   - For backend queries, use `fetch("https://your-api.com/...")` with full HTTPS.
4. **Offline-First Persistence:**
   - App must boot without an internet connection.
   - Use `localStorage` or `IndexedDB` for local state persistence.
5. **Mobile Viewport & Safe Areas:**
   - Viewport meta tag: `<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">`.
   - Respect notch insets using `padding-top: env(safe-area-inset-top)`.

---

## 🏪 Google Play Store Publishing Standards (Important for AI)
When suggesting version bumps, assets, or packaging, adhere to:
1. **App Format:** Target Android App Bundle (`.aab`) for production uploads.
2. **Unique Version Code:** Every store release requires an incrementally higher integer `versionCode` in `android/app/build.gradle`.
3. **Store Assets:** 
   - Icon: `512x512 px` (32-bit PNG)
   - Feature Graphic: `1024x500 px` (JPG or 24-bit PNG)
   - Minimum 2 phone screenshots
4. **Closed Testing Rule:** Accounts created after Nov 2023 require at least 20 testers for 14 continuous days before production release.
5. **Full Guide:** Refer to `GOOGLE_PLAY_STORE_GUIDE.md` for complete technical policy requirements.

---

## 🐘 Automated Cloud Gradle Build & GitHub Release Pipeline
The GitHub Actions workflow `.github/workflows/build-apk.yml`:
1. Pulls the latest code, installs Capacitor, and runs `npx cap sync android`.
2. Compiles:
   - **`app-debug.apk`**: Direct download for instant testing on Android devices.
   - **`app-debug.aab`**: Android App Bundle for Google Play Console.
3. **Automatically publishes a GitHub Release** tagged `v1.0.<run_number>` with direct download links attached!
