# 🤖 AI Assistant Guidelines & Development Rules (Capacitor + Cloud Gradle)

> **Feed this file (or `<REPO_NAME>_ALL_IN_ONE.txt` / `<REPO_NAME>_ALL_IN_ONE_FIX.txt`) to ChatGPT, Claude, Gemini, or Antigravity to build features with 100% Capacitor, Gradle & Google Play compatibility.**

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

## ⚡ 0ms Fast & Smooth Performance Standard (No Animation Bloat)
- **What "Smooth" Means:** "Smoother" does **NOT** mean adding heavy 60fps/120fps physics loops, complex canvas particle engines, or high-overhead transitions that bog down mobile CPU/GPUs and make phones laggy.
- **Fast & 0ms Responsive Rules:**
  - **0ms Startup:** Keep `launchShowDuration: 0` in `capacitor.config.json`. Do not insert artificial loading screens, timers, or splash delays.
  - **0ms Tap Response:** Use `touch-action: manipulation` and `-webkit-tap-highlight-color: transparent` to eliminate the 300ms mobile browser click latency.
  - **Snappy Transitions:** UI changes and view switches should be instantaneous or use micro-transitions (<= 100ms).
  - **Zero CPU Hogs:** Avoid non-stop `setInterval` or `requestAnimationFrame` loops when the screen is idle.

---

## 🏷️ Custom Binary Naming Standard (No Generic 'app-debug.apk')
- Never name compiled releases or APK downloads `app-debug.apk` or `app-debug.aab`.
- All outputs are packaged and tagged as **`<RepoName>-<Version>.apk`** and **`<RepoName>-<Version>.aab`** (e.g. `<RepoName>-v1.0.12.apk`).

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

## 🎨 App Icon Placement & Automated Density Generation
- **Where to place your icon:** Put your high-resolution icon at `assets/icon.png` (or `icon.png` in root).
- **Format:** `512x512 px` (or 1024x1024 px) PNG.
- **Automated Generation:** The cloud build pipeline automatically resizes `assets/icon.png` into all Android launcher mipmap densities (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) including adaptive foreground and round icons, as well as web PWA icons (`src/icon-192.png`, `src/icon-512.png`).
- **Instant Launch (Zero Splash Screen Delay):**
  - Configured with `launchShowDuration: 0` and `showSpinner: false` in `capacitor.config.json` with a clean launch drawable. The web app boots smoothly and instantly (0ms).

---

## 🐘 Automated Cloud CI/CD Workflows
1. **`build-apk.yml`:** Automatically compiles `<RepoName>-<Version>.apk` and `<RepoName>-<Version>.aab` and publishes a GitHub Release.
2. **`deploy-pages.yml`:** Deploys `src/` to GitHub Pages for instant live web preview.
3. **`audit-mobile.yml`:** Protects against white blank screens by catching broken absolute paths.
4. **`clean-artifacts.yml`:** Prunes old build artifacts to save GitHub storage.


