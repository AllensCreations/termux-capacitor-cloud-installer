#!/usr/bin/env bash
# ==============================================================================
# Remote Capacitor/Gradle Cloud Workflow Installer for Termux & Linux
# ==============================================================================

set -eo pipefail

# ------------------------------------------------------------------------------
# Terminal & Input Handling (Support curl | bash with interactive tty)
# ------------------------------------------------------------------------------
if [ ! -t 0 ] && [ -e /dev/tty ]; then
  exec < /dev/tty
fi

# Color helpers
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

clear 2>/dev/null || true
echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║       ⚡ REMOTE CAPACITOR & CLOUD GRADLE WORKFLOW INSTALLER ⚡             ║
║            Zero-Setup Android APKs via GitHub Actions & Termux             ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Find script template directory if running locally or prepare fallback
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

# ------------------------------------------------------------------------------
# Step 1: Check & Install Dependencies (gh, jq, git, curl)
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/6] 🔍 Checking environment & dependencies...${NC}"

is_termux=false
if [ -d "/data/data/com.termux" ] || command -v termux-setup-storage >/dev/null 2>&1; then
  is_termux=true
  echo -e "      📱 Environment detected: ${GREEN}Termux (Android)${NC}"
fi

missing_pkgs=()
for cmd in gh jq git curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_pkgs+=("$cmd")
  fi
done

if [ ${#missing_pkgs[@]} -gt 0 ]; then
  echo -e "      ${YELLOW}Missing packages:${NC} ${missing_pkgs[*]}"
  if [ "$is_termux" = true ]; then
    echo -e "      Installing via ${CYAN}pkg install -y ${missing_pkgs[*]}${NC}..."
    pkg update -y && pkg install -y "${missing_pkgs[@]}"
  else
    echo -e "      Please ensure ${missing_pkgs[*]} are installed."
    exit 1
  fi
else
  echo -e "      ${GREEN}✓ All tools verified (gh, jq, git, curl).${NC}"
fi

# ------------------------------------------------------------------------------
# Step 2: GitHub CLI Authentication
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/6] 🔑 Verifying GitHub authentication...${NC}"

if ! gh auth status >/dev/null 2>&1; then
  echo -e "      ${YELLOW}⚠️ Not logged into GitHub.${NC}"
  echo -e "      Launching ${CYAN}gh auth login${NC}..."
  gh auth login -h github.com -p https -w
fi

gh auth setup-git >/dev/null 2>&1 || true
gh_user=$(gh api user -q .login 2>/dev/null || echo "user")
echo -e "      ${GREEN}✓ Logged in as:${NC} ${BOLD}${gh_user}${NC}"

# ------------------------------------------------------------------------------
# Step 3: Action Selection (New Repo Recommended)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/6] 🎯 Choose Setup Mode:${NC}\n"
echo -e "  ${GREEN}${BOLD}[1] 🌟 Create a Brand New Clean Repository (Recommended)${NC}"
echo -e "      Scaffolds a pristine offline-first app, AI instructions, and Gradle CI."
echo -e "  ${CYAN}[2] 📂 Select an Existing Repository from GitHub${NC}"
echo -e "      Injects Capacitor & Gradle CI into one of your existing repos."
echo -e "  ${YELLOW}[3] 💻 Use an Existing Local Folder${NC}"
echo -e "      Configures a folder already on your device."

echo ""
read -rp "Enter choice [1, 2, or 3] (Default: 1): " mode_choice
mode_choice="${mode_choice:-1}"

TARGET_DIR=""
SELECTED_REPO=""
IS_NEW_REPO=false
IS_LOCAL=false

if [ "$mode_choice" = "1" ]; then
  IS_NEW_REPO=true
  echo -e "\n${BOLD}--- 🌟 Create New GitHub Repository ---${NC}"
  read -rp "Enter new repository name (e.g. my-mobile-app): " NEW_REPO_NAME
  NEW_REPO_NAME=$(echo "$NEW_REPO_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-_')
  
  if [ -z "$NEW_REPO_NAME" ]; then
    NEW_REPO_NAME="offline-mobile-app-$(date +%s)"
    echo "Using generated name: $NEW_REPO_NAME"
  fi

  read -rp "Repository visibility [public/private] (Default: public): " REPO_VIS
  REPO_VIS="${REPO_VIS:-public}"
  if [[ ! "$REPO_VIS" =~ ^(public|private)$ ]]; then
    REPO_VIS="public"
  fi

  read -rp "Description (Optional): " REPO_DESC
  REPO_DESC="${REPO_DESC:-Offline-first Capacitor app built with Cloud Gradle}"

  CLONE_DIR="${TMPDIR:-/tmp}/new-repo-$NEW_REPO_NAME"
  rm -rf "$CLONE_DIR"
  echo -e "\nCreating GitHub repository ${CYAN}${gh_user}/${NEW_REPO_NAME}${NC}..."
  gh repo create "$NEW_REPO_NAME" "--$REPO_VIS" --description "$REPO_DESC" --clone "$CLONE_DIR"
  
  SELECTED_REPO="${gh_user}/${NEW_REPO_NAME}"
  TARGET_DIR="$CLONE_DIR"

elif [ "$mode_choice" = "2" ]; then
  echo -e "\nFetching your GitHub repositories..."
  mapfile -t repos < <(gh repo list --limit 25 --json nameWithOwner,isPrivate,description --jq '.[] | "\(.nameWithOwner)\t\(if .isPrivate then "[Private]" else "[Public]" end)\t\(.description // "")"')
  
  idx=1
  for r in "${repos[@]}"; do
    r_name=$(echo "$r" | awk -F'\t' '{print $1}')
    r_vis=$(echo "$r" | awk -F'\t' '{print $2}')
    printf "  [%2d] %-35s %s\n" "$idx" "$r_name" "$r_vis"
    ((idx++))
  done
  read -rp "Select repository [1-$((idx-1))]: " repo_num
  if [[ "$repo_num" =~ ^[0-9]+$ ]] && [ "$repo_num" -ge 1 ] && [ "$repo_num" -lt "$idx" ]; then
    SELECTED_REPO=$(echo "${repos[$((repo_num-1))]}" | awk -F'\t' '{print $1}')
  else
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
  fi

  CLONE_DIR="${TMPDIR:-/tmp}/existing-repo-$(date +%s)"
  echo -e "\nCloning ${SELECTED_REPO}..."
  git clone "https://github.com/$SELECTED_REPO.git" "$CLONE_DIR"
  TARGET_DIR="$CLONE_DIR"

elif [ "$mode_choice" = "3" ]; then
  IS_LOCAL=true
  read -rp "Enter full path to local directory: " TARGET_DIR
  if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Directory does not exist: $TARGET_DIR${NC}"
    exit 1
  fi
  SELECTED_REPO=$(basename "$TARGET_DIR")
fi

cd "$TARGET_DIR"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
[ -z "$CURRENT_BRANCH" ] && CURRENT_BRANCH="main"

# ------------------------------------------------------------------------------
# Step 4: Scaffold UI & Offline-First src/ Architecture
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/6] 📁 Structuring offline-first architecture (src/)...${NC}"

mkdir -p "$TARGET_DIR/src/css" "$TARGET_DIR/src/js" "$TARGET_DIR/src/assets"

# If starter files exist in templates, copy them; otherwise generate clean starter UI
if [ "$IS_NEW_REPO" = true ] || [ ! -f "$TARGET_DIR/src/index.html" ]; then
  # 1. src/index.html
  cat << 'HTML' > "$TARGET_DIR/src/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <title>Offline Mobile App</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div class="app-shell">
    <header class="app-header">
      <div class="header-content">
        <span class="app-badge">Capacitor + Gradle</span>
        <div id="connection-status" class="status-pill status-offline">● Checking...</div>
      </div>
      <h1>Offline-First App</h1>
      <p class="subtitle">Cloud-Compiled Android APK via GitHub Actions</p>
    </header>

    <main class="app-main">
      <section class="card">
        <h2>💾 Local Offline Storage Demo</h2>
        <p>This state is saved purely on your device using <code>localStorage</code>.</p>
        <div class="counter-box">
          <button id="btn-decrement" class="btn btn-secondary">-</button>
          <span id="counter-value" class="counter-display">0</span>
          <button id="btn-increment" class="btn btn-primary">+</button>
        </div>
      </section>

      <section class="card">
        <h2>🤖 AI-Assisted Development</h2>
        <p>Your repository contains <code>AI_INSTRUCTIONS.md</code> and <code>REPO_ALL_IN_ONE.txt</code>.</p>
        <p class="hint">Feed these files to ChatGPT, Claude, or Gemini to build features adhering to strict Capacitor & Gradle mobile rules.</p>
      </section>
    </main>

    <footer class="app-footer">
      <p>Target Directory: <code>src/</code> • Scheme: <code>https://localhost</code></p>
    </footer>
  </div>

  <script src="js/app.js"></script>
</body>
</html>
HTML

  # 2. src/css/style.css
  cat << 'CSS' > "$TARGET_DIR/src/css/style.css"
:root {
  --bg-color: #0d1117;
  --surface-color: #161b22;
  --border-color: #30363d;
  --primary-color: #2ea043;
  --text-main: #f0f6fc;
  --text-muted: #8b949e;
}
* { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background-color: var(--bg-color);
  color: var(--text-main);
  min-height: 100vh;
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  display: flex;
  justify-content: center;
}
.app-shell { width: 100%; max-width: 480px; display: flex; flex-direction: column; padding: 24px 16px; }
.app-header { margin-bottom: 24px; }
.header-content { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.app-badge { font-size: 11px; font-weight: 700; text-transform: uppercase; background: #1f6feb22; color: #58a6ff; border: 1px solid #1f6feb55; padding: 4px 8px; border-radius: 12px; }
.status-pill { font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 12px; }
.status-online { background: #23863633; color: #3fb950; border: 1px solid #23863666; }
.status-offline { background: #da363333; color: #f85149; border: 1px solid #da363366; }
h1 { font-size: 26px; font-weight: 700; margin-bottom: 6px; }
.subtitle { font-size: 14px; color: var(--text-muted); }
.app-main { flex: 1; display: flex; flex-direction: column; gap: 16px; }
.card { background-color: var(--surface-color); border: 1px solid var(--border-color); border-radius: 12px; padding: 18px; }
.card h2 { font-size: 18px; margin-bottom: 8px; }
.card p { font-size: 14px; color: var(--text-muted); line-height: 1.5; margin-bottom: 12px; }
.hint { font-size: 13px !important; color: #79c0ff !important; background: #0d419d22; padding: 8px 12px; border-radius: 8px; border-left: 3px solid #1f6feb; }
.counter-box { display: flex; align-items: center; justify-content: center; gap: 20px; margin-top: 16px; }
.counter-display { font-size: 32px; font-weight: 700; min-width: 48px; text-align: center; }
.btn { width: 48px; height: 48px; border-radius: 50%; border: none; font-size: 22px; font-weight: bold; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.btn:active { transform: scale(0.95); }
.btn-primary { background: var(--primary-color); color: white; }
.btn-secondary { background: #21262d; color: white; border: 1px solid var(--border-color); }
.app-footer { text-align: center; margin-top: 32px; font-size: 12px; color: var(--text-muted); }
code { background: rgba(110, 118, 129, 0.2); padding: 2px 6px; border-radius: 4px; font-family: monospace; }
CSS

  # 3. src/js/app.js
  cat << 'JS' > "$TARGET_DIR/src/js/app.js"
document.addEventListener("DOMContentLoaded", () => {
  const statusEl = document.getElementById("connection-status");
  function update() {
    if (!statusEl) return;
    statusEl.textContent = navigator.onLine ? "● Online" : "● Offline (Local Mode)";
    statusEl.className = navigator.onLine ? "status-pill status-online" : "status-pill status-offline";
  }
  window.addEventListener("online", update);
  window.addEventListener("offline", update);
  update();

  const display = document.getElementById("counter-value");
  const btnInc = document.getElementById("btn-increment");
  const btnDec = document.getElementById("btn-decrement");
  if (display && btnInc && btnDec) {
    let count = parseInt(localStorage.getItem("offline_counter") || "0", 10);
    display.textContent = count;
    btnInc.addEventListener("click", () => { count++; localStorage.setItem("offline_counter", count); display.textContent = count; });
    btnDec.addEventListener("click", () => { count--; localStorage.setItem("offline_counter", count); display.textContent = count; });
  }
});
JS
  echo -e "      ${GREEN}✓ Created offline-first mobile UI in src/${NC}"
fi

# Ensure package.json exists
if [ ! -f "$TARGET_DIR/package.json" ]; then
  cat << PKG > "$TARGET_DIR/package.json"
{
  "name": "${SELECTED_REPO##*/}",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "npx cap copy",
    "cap:sync": "npx cap sync android"
  }
}
PKG
fi

# ------------------------------------------------------------------------------
# Step 5: Inject Capacitor Config, CI Workflow & AI Instructions
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[5/6] ⚙️ Injecting Capacitor config, Gradle workflow & AI docs...${NC}"

# 1. capacitor.config.json
app_slug=$(echo "${SELECTED_REPO##*/}" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
[ -z "$app_slug" ] && app_slug="app"

cat << CAPCONFIG > "$TARGET_DIR/capacitor.config.json"
{
  "appId": "com.cloud.${app_slug}",
  "appName": "${SELECTED_REPO##*/}",
  "webDir": "src",
  "bundledWebRuntime": false,
  "server": {
    "androidScheme": "https"
  }
}
CAPCONFIG

# 2. .github/workflows/build-apk.yml
mkdir -p "$TARGET_DIR/.github/workflows"
cat << 'WORKFLOW' > "$TARGET_DIR/.github/workflows/build-apk.yml"
name: Build Android APK (Capacitor + Gradle)

on:
  push:
    branches: [ main, master, Version2 ]
  workflow_dispatch:

jobs:
  build-android:
    name: Cloud Capacitor & Gradle APK Builder
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout Repository
        uses: actions/checkout@v4

      - name: ☕ Set up Java JDK 17 (Temurin)
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: 📱 Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: 🟩 Set up Node.js 20
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
          cache-dependency-path: '**/package-lock.json'
        continue-on-error: true

      - name: 📦 Install Capacitor Core & Android CLI
        run: |
          if [ ! -f package.json ]; then
            npm init -y
          fi
          npm install --save @capacitor/core @capacitor/cli @capacitor/android

      - name: 🛠️ Ensure Web Directory and Entrypoint Exist
        run: |
          if [ ! -d "src" ]; then
            mkdir -p src
            if [ -f "index.html" ]; then
              cp index.html src/
            else
              echo "<!DOCTYPE html><html><head><title>Offline App</title></head><body><h1>Welcome</h1></body></html>" > src/index.html
            fi
          fi

      - name: ⚡ Initialize Android Platform & Sync Web Assets
        run: |
          if [ ! -d "android" ]; then
            npx cap add android
          fi
          npx cap sync android

      - name: 🐘 Compile APK with Gradle
        run: |
          cd android
          chmod +x gradlew
          ./gradlew assembleDebug --stacktrace

      - name: 📤 Upload Debug APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-debug-apk
          path: android/app/build/outputs/apk/debug/app-debug.apk
          retention-days: 14

      - name: 📋 Summary
        run: |
          echo "### 🚀 Build Successful!" >> $GITHUB_STEP_SUMMARY
          echo "The Android APK was compiled using Gradle in the GitHub Cloud runner." >> $GITHUB_STEP_SUMMARY
          echo "- **Artifact Name:** \`app-debug-apk\`" >> $GITHUB_STEP_SUMMARY
          echo "- **Download via Termux:** \`gh run download ${{ github.run_id }} -n app-debug-apk\`" >> $GITHUB_STEP_SUMMARY
WORKFLOW

# 3. AI_INSTRUCTIONS.md
cat << 'AI_DOC' > "$TARGET_DIR/AI_INSTRUCTIONS.md"
# 🤖 AI Assistant Guidelines & Development Rules (Capacitor + Cloud Gradle)

> **Feed this file (or `REPO_ALL_IN_ONE.txt`) to ChatGPT, Claude, Gemini, or Antigravity to build features with 100% Capacitor & Gradle compatibility.**

---

## 🎯 System Prompt & Architecture Constraints
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

## 🐘 How Cloud Gradle Builds the APK
The GitHub Actions workflow `.github/workflows/build-apk.yml` runs on Ubuntu cloud runners. It installs Capacitor, runs `npx cap sync android` to copy `src/` into the native Android folder, and executes `./gradlew assembleDebug` to compile `app-debug.apk`.
AI_DOC

# 4. FOLDER_ORGANIZATION.md
cat << 'ORG_DOC' > "$TARGET_DIR/FOLDER_ORGANIZATION.md"
# Project Layout & Architecture Guide (Offline-First Capacitor)

```
.
├── src/                               # 🌐 Web Assets & Application Core (Capacitor webDir)
│   ├── index.html                     # 🎯 Primary offline entry point
│   ├── css/                           # 🎨 Styling & stylesheets (style.css)
│   ├── js/                            # ⚙️ Application logic (app.js)
│   └── assets/                        # 🖼️ Offline icons, images, fonts
│
├── .github/workflows/build-apk.yml    # 🤖 Cloud CI/CD: Capacitor sync + Gradle APK build
├── capacitor.config.json              # 📱 Capacitor native bridge configuration
├── AI_INSTRUCTIONS.md                 # 🤖 AI assistant prompts & mobile rules
├── FOLDER_ORGANIZATION.md             # 📖 Architecture & layout blueprint
├── README.md                          # 🚀 Project documentation & APK download guide
└── REPO_ALL_IN_ONE.txt                # 🧠 Consolidated codebase digest with AI prompt
```
ORG_DOC

# 5. README.md
cat << README_DOC > "$TARGET_DIR/README.md"
# ${SELECTED_REPO##*/} (Offline-First Capacitor + Cloud Gradle)

An offline-first hybrid mobile app structured for **Capacitor** with automated **GitHub Actions Gradle APK compilation**.

---

## 🚀 Development & Structure
- **Web Source:** All client code lives in \`src/\`.
- **Entrypoint:** \`src/index.html\`
- **Styles:** \`src/css/style.css\`
- **Scripts:** \`src/js/app.js\`

See [FOLDER_ORGANIZATION.md](FOLDER_ORGANIZATION.md) for full directory specifications and [AI_INSTRUCTIONS.md](AI_INSTRUCTIONS.md) for AI-assisted development instructions.

---

## 🤖 Cloud Gradle APK Compilation
Trigger APK build manually via Termux or any terminal:
\`\`\`bash
gh workflow run build-apk.yml
\`\`\`

Download the finished APK:
\`\`\`bash
gh run download -n app-debug-apk
mv app-debug.apk /sdcard/Download/
\`\`\`
README_DOC

# ------------------------------------------------------------------------------
# Step 6: Generate All-in-One Code Digest (REPO_ALL_IN_ONE.txt)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[6/6] 🧠 Generating All-in-One Code Digest with AI Prompt...${NC}"

AI_PROMPT='Act as an expert mobile developer and project organizer. Review the provided repository files and develop the application following a clean, minimal, and scalable offline-first Capacitor architecture. Group all web source assets into a dedicated src/ directory with explicit subfolders for CSS (src/css/) and JavaScript (src/js/), ensuring index.html remains the primary offline entry point at the root of src/. Verify that the capacitor.config.json correctly targets src as its webDir. Ensure all paths in index.html are strictly relative, that offline storage (localStorage/IndexedDB) is utilized, and outline how the automated GitHub Actions workflow compiles the project into an Android APK via Gradle.'

OUTPUT_DIGEST="$TARGET_DIR/REPO_ALL_IN_ONE.txt"
rm -f "$OUTPUT_DIGEST"

cat << PROMPT_BLOCK > "$OUTPUT_DIGEST"
================================================================================
AI SYSTEM & ARCHITECTURE PROMPT:
$AI_PROMPT
================================================================================

PROJECT DIRECTORY OVERVIEW
Generated: $(date -u +"%Y-%m-%d %H:%M:%SZ")
Repository: $SELECTED_REPO
--------------------------------------------------------------------------------
PROMPT_BLOCK

# Add directory tree
if command -v tree >/dev/null 2>&1; then
  (cd "$TARGET_DIR" && tree -a -I '.git|node_modules|android|.gradle|build|dist') >> "$OUTPUT_DIGEST"
else
  (cd "$TARGET_DIR" && find . -maxdepth 4 -not -path '*/.*' -not -path './node_modules*' -not -path './android*' | sort) >> "$OUTPUT_DIGEST"
fi

cat << 'SEPARATOR' >> "$OUTPUT_DIGEST"

================================================================================
CONSOLIDATED SOURCE CODE FILES
================================================================================
SEPARATOR

IGNORE_PATTERN="(\.git|\.gradle|android|node_modules|build|dist|\.wrangler|\.idea|\.vscode)"
BINARY_EXTENSIONS="png|jpg|jpeg|gif|svg|ico|webp|mp3|mp4|apk|aab|keystore|jar|zip|gz|tar|woff|woff2|ttf|eot|pdf"

find "$TARGET_DIR" -type f | while read -r filepath; do
  relpath="${filepath#$TARGET_DIR/}"
  [ "$filepath" = "$OUTPUT_DIGEST" ] && continue
  echo "$relpath" | grep -qE "$IGNORE_PATTERN" && continue
  echo "$relpath" | grep -qiE "\.($BINARY_EXTENSIONS)$" && continue

  filesize=$(wc -c < "$filepath" 2>/dev/null || echo 0)
  [ "$filesize" -gt 1048576 ] && continue

  if [ -r "$filepath" ]; then
    cat << FILE_HEADER >> "$OUTPUT_DIGEST"

--------------------------------------------------------------------------------
FILE: $relpath
--------------------------------------------------------------------------------
FILE_HEADER
    cat "$filepath" >> "$OUTPUT_DIGEST"
    echo "" >> "$OUTPUT_DIGEST"
  fi
done

echo -e "      ${GREEN}✓ Digest created:${NC} ${BOLD}REPO_ALL_IN_ONE.txt${NC}"

# ------------------------------------------------------------------------------
# Git Commit, Push & Dispatch
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}🚀 Pushing project to GitHub...${NC}"
cd "$TARGET_DIR"
git add .
if git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "      No changes needed to commit."
else
  git commit -m "feat: initial offline-first capacitor setup with cloud gradle CI and AI instructions"
  git push -u origin "$CURRENT_BRANCH"
  echo -e "      ${GREEN}✓ Successfully pushed to GitHub!${NC}"
fi

echo -e "\n${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}🎉 SUCCESS! Your Project is Live on GitHub!${NC}"
echo -e "Repository: ${CYAN}https://github.com/${SELECTED_REPO}${NC}"
echo -e "════════════════════════════════════════════════════════════════"
echo -e "✨ ${BOLD}How to use this with an AI Assistant:${NC}"
echo -e "   1. Open ${CYAN}REPO_ALL_IN_ONE.txt${NC} or ${CYAN}AI_INSTRUCTIONS.md${NC}."
echo -e "   2. Copy and paste the contents into ChatGPT, Claude, Gemini, or Antigravity."
echo -e "   3. Ask the AI to build screens or features—it will strictly respect"
echo -e "      relative paths, offline storage, and Capacitor/Gradle standards!\n"

if [ "$IS_LOCAL" = false ]; then
  read -rp "Would you like to trigger the Cloud APK build right now? [y/N]: " run_now
  if [[ "$run_now" =~ ^[Yy]$ ]]; then
    echo -e "Triggering GitHub Actions workflow..."
    gh workflow run build-apk.yml --repo "$SELECTED_REPO"
    echo -e "${GREEN}✓ Workflow dispatched in the cloud!${NC}"
    echo -e "Check progress: ${CYAN}gh run list --repo $SELECTED_REPO${NC}"
    echo -e "Download APK:   ${CYAN}gh run download --repo $SELECTED_REPO -n app-debug-apk${NC}"
  fi
fi
