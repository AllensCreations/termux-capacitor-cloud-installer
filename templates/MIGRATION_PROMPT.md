# 🛠️ AI Codebase Refactoring & Migration Prompt

> **When installing Capacitor into an EXISTING repository, copy and paste the prompt below (or `FIX_EXISTING_REPO_ALL_IN_ONE.txt`) into ChatGPT, Claude, Gemini, or Antigravity to safely adapt your code without breaking it.**

---

```text
================================================================================
AI MIGRATION & REFACTORING PROMPT: SAFE CAPACITOR & GRADLE CONVERSION
================================================================================
Act as a Senior Principal Mobile Engineer and Codebase Migration Specialist. 
Review the provided existing repository files below and refactor the project layout into a clean, minimal, and scalable offline-first Capacitor architecture without breaking any existing functionality.

OBJECTIVE:
Analyze the full source code provided and output a non-destructive migration plan and exact file modifications to achieve 100% compatibility with Capacitor, Gradle APK/AAB builds, and Google Play Store policies.

STRICT CONSTRAINTS & AUDIT RULES:
1. ZERO BREAKING CHANGES:
   - Preserve all existing UI, business logic, state handling, routes, and feature behaviors.
   - Do not delete existing assets or change variable names unless necessary for mobile compatibility.

2. WEB ASSETS RESTRUCTURING (src/):
   - Group all client-facing web assets into a dedicated `src/` directory (`src/index.html`, `src/css/`, `src/js/`, `src/assets/`).
   - Ensure `capacitor.config.json` correctly points to `"webDir": "src"`.

3. STRICT RELATIVE PATH CONVERSION (CRITICAL):
   - In Android WebViews, absolute root paths (e.g. `/style.css`, `/app.js`, `/images/logo.png`) result in blank screens.
   - Convert all asset and script references in `index.html`, JS, and CSS to strictly relative paths (e.g. `css/style.css`, `js/app.js`, `./assets/logo.png`).

4. FRONTEND / BACKEND DECOUPLING:
   - Identify any server-side runtime code (Node.js, Express, server.js, Cloudflare workers).
   - Ensure backend files remain outside of `src/` so they are not bundled into the client APK.
   - If the frontend communicates with the backend, ensure full HTTPS URLs are used with graceful offline error handling.

5. OFFLINE-FIRST RESILIENCE:
   - Ensure the app can boot and render cleanly even if the user opens the app while in Airplane mode or without internet.
   - Use `localStorage` or `IndexedDB` for offline state storage.

6. GOOGLE PLAY & GRADLE READINESS:
   - Adhere to `GOOGLE_PLAY_STORE_GUIDE.md` (e.g. incremental `versionCode` in build.gradle, Android App Bundle `.aab` format).

OUTPUT FORMAT REQUIRED:
1. Audit Summary: Detailed list of potential breaking points found (absolute paths, server dependencies, missing offline handlers).
2. Refactored File Tree: Explicit layout of the restructured repository.
3. Code Replacements / Unified Diffs: Complete, drop-in replacement code for any modified files with exact filepaths.
4. Verification Instructions: How to test the refactored code both in a browser and as a compiled Android APK.
================================================================================
```
