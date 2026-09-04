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
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║       ⚡ REMOTE CAPACITOR & CLOUD GRADLE WORKFLOW INSTALLER ⚡             ║
║                  Termux & Cloud CI/CD Automation Engine                    ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# ------------------------------------------------------------------------------
# Step 1: Check & Install Dependencies (gh, jq, git, curl)
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/7] Checking environment and dependencies...${NC}"

is_termux=false
if [ -d "/data/data/com.termux" ] || command -v termux-setup-storage >/dev/null 2>&1; then
  is_termux=true
  echo -e "📱 Environment detected: ${GREEN}Termux (Android)${NC}"
fi

missing_pkgs=()
for cmd in gh jq git curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_pkgs+=("$cmd")
  fi
done

if [ ${#missing_pkgs[@]} -gt 0 ]; then
  echo -e "${YELLOW}Missing packages:${NC} ${missing_pkgs[*]}"
  if [ "$is_termux" = true ]; then
    echo -e "Installing via ${CYAN}pkg install -y ${missing_pkgs[*]}${NC}..."
    pkg update -y && pkg install -y "${missing_pkgs[@]}"
  else
    echo -e "Please ensure ${missing_pkgs[*]} are installed on your system."
  fi
else
  echo -e "${GREEN}✓ All dependencies are installed (gh, jq, git, curl).${NC}"
fi

# ------------------------------------------------------------------------------
# Step 2: GitHub CLI Authentication
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/7] Verifying GitHub authentication...${NC}"

if ! gh auth status >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️ You are not logged in to GitHub.${NC}"
  echo -e "Launching ${CYAN}gh auth login${NC} (Select 'GitHub.com', 'HTTPS', and authenticate with browser/code)..."
  gh auth login
fi

gh_user=$(gh api user -q .login 2>/dev/null || echo "")
echo -e "${GREEN}✓ Authenticated as GitHub user:${NC} ${BOLD}${gh_user}${NC}"

# ------------------------------------------------------------------------------
# Step 3: Select Target Repository
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/7] Fetching your GitHub repositories...${NC}"

mapfile -t repos < <(gh repo list --limit 30 --json nameWithOwner,isPrivate,description --jq '.[] | "\(.nameWithOwner)\t\(if .isPrivate then "[Private]" else "[Public]" end)\t\(.description // "No description")"')

if [ ${#repos[@]} -eq 0 ]; then
  echo -e "${YELLOW}No repositories found under account. You can specify one manually.${NC}"
fi

echo -e "\nSelect a repository to install Capacitor & Cloud Gradle into:\n"
idx=1
for r in "${repos[@]}"; do
  r_name=$(echo "$r" | awk -F'\t' '{print $1}')
  r_vis=$(echo "$r" | awk -F'\t' '{print $2}')
  r_desc=$(echo "$r" | awk -F'\t' '{print $3}')
  printf "  ${CYAN}[%2d]${NC} ${BOLD}%-35s${NC} %-10s %s\n" "$idx" "$r_name" "$r_vis" "$r_desc"
  ((idx++))
done
printf "  ${YELLOW}[ M]${NC} Enter repository manually (e.g. username/my-app)\n"
printf "  ${YELLOW}[ L]${NC} Use an existing local folder\n\n"

read -rp "Enter choice [1-$((idx-1)), M, or L]: " user_choice

TARGET_DIR=""
SELECTED_REPO=""
IS_LOCAL=false

if [[ "$user_choice" =~ ^[0-9]+$ ]] && [ "$user_choice" -ge 1 ] && [ "$user_choice" -lt "$idx" ]; then
  SELECTED_REPO=$(echo "${repos[$((user_choice-1))]}" | awk -F'\t' '{print $1}')
elif [[ "$user_choice" =~ ^[Mm]$ ]]; then
  read -rp "Enter GitHub repository (owner/repo): " SELECTED_REPO
elif [[ "$user_choice" =~ ^[Ll]$ ]]; then
  IS_LOCAL=true
  read -rp "Enter absolute path to local folder: " TARGET_DIR
  if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Directory does not exist: $TARGET_DIR${NC}"
    exit 1
  fi
else
  echo -e "${RED}Invalid selection. Exiting.${NC}"
  exit 1
fi

# Clone repository if remote
if [ "$IS_LOCAL" = false ]; then
  repo_basename=$(basename "$SELECTED_REPO")
  CLONE_DIR="${TMPDIR:-/tmp}/cloud-installer-$repo_basename-$(date +%s)"
  echo -e "\n📥 Cloning ${BOLD}$SELECTED_REPO${NC} into temporary workspace..."
  git clone "https://github.com/$SELECTED_REPO.git" "$CLONE_DIR"
  TARGET_DIR="$CLONE_DIR"
fi

# Detect default branch
cd "$TARGET_DIR"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
echo -e "🌿 Target branch: ${CYAN}$CURRENT_BRANCH${NC}"

# ------------------------------------------------------------------------------
# Step 4: Scaffold / Restructure Offline-First src/ Layout
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/7] Structuring offline-first Capacitor architecture (src/)...${NC}"

mkdir -p "$TARGET_DIR/src/css" "$TARGET_DIR/src/js" "$TARGET_DIR/src/assets"

# Check if index.html is at root and move to src/ if not already in src/
if [ -f "$TARGET_DIR/index.html" ] && [ ! -f "$TARGET_DIR/src/index.html" ]; then
  echo "Moving root index.html to src/index.html..."
  mv "$TARGET_DIR/index.html" "$TARGET_DIR/src/index.html"
elif [ ! -f "$TARGET_DIR/src/index.html" ]; then
  echo "Creating default offline-first src/index.html..."
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
  <div class="container">
    <h1>🚀 Offline Capacitor App</h1>
    <p>Compiled natively via Cloud Gradle & GitHub Actions.</p>
  </div>
  <script src="js/app.js"></script>
</body>
</html>
HTML
fi

# Create default css/js if empty
if [ ! -f "$TARGET_DIR/src/css/style.css" ]; then
  # Look for root css
  root_css=$(find "$TARGET_DIR" -maxdepth 1 -name "*.css" | head -n 1)
  if [ -n "$root_css" ]; then
    echo "Relocating $root_css to src/css/style.css..."
    mv "$root_css" "$TARGET_DIR/src/css/style.css"
  else
    cat << 'CSS' > "$TARGET_DIR/src/css/style.css"
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #121212; color: #ffffff; padding: 20px; }
.container { max-width: 600px; margin: 40px auto; text-align: center; }
h1 { color: #00e676; margin-bottom: 12px; }
CSS
  fi
fi

if [ ! -f "$TARGET_DIR/src/js/app.js" ]; then
  root_js=$(find "$TARGET_DIR" -maxdepth 1 -name "*.js" -not -name "server.js" -not -name "capacitor.config.js" | head -n 1)
  if [ -n "$root_js" ]; then
    echo "Relocating $root_js to src/js/app.js..."
    mv "$root_js" "$TARGET_DIR/src/js/app.js"
  else
    cat << 'JS' > "$TARGET_DIR/src/js/app.js"
document.addEventListener("DOMContentLoaded", () => {
  console.log("Offline Capacitor Application Initialized");
});
JS
  fi
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
# Step 5: Inject Capacitor Config & Cloud Gradle Workflow
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[5/7] Injecting Capacitor config & GitHub Actions Cloud Gradle workflow...${NC}"

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

# 3. FOLDER_ORGANIZATION.md
cat << 'ORG_DOC' > "$TARGET_DIR/FOLDER_ORGANIZATION.md"
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
ORG_DOC

# 4. Update or Create README.md
if [ ! -f "$TARGET_DIR/README.md" ]; then
  cat << README_TPL > "$TARGET_DIR/README.md"
# ${SELECTED_REPO##*/} (Capacitor + Cloud Gradle Builder)

An offline-first mobile application structured for **Capacitor** with automated **GitHub Actions Gradle APK compilation**.

---

## 🚀 Quick Start & Development

- **Web Source:** All client code lives in \`src/\`.
- **Offline Entrypoint:** \`src/index.html\`
- **Styles:** \`src/css/style.css\`
- **Scripts:** \`src/js/app.js\`

For full details on the directory hierarchy and architecture decisions, see [FOLDER_ORGANIZATION.md](FOLDER_ORGANIZATION.md).

---

## 🤖 Cloud Gradle APK Compilation

You do **not** need to install heavy Android SDKs or Gradle locally. Every push to the repository automatically triggers the GitHub Actions workflow to build the Android APK.

### Trigger Build Manually (Termux or Terminal)
\`\`\`bash
gh workflow run build-apk.yml
\`\`\`

### Download the Compiled APK
\`\`\`bash
# List recent build runs
gh run list --workflow=build-apk.yml

# Download the latest artifact
gh run download --name app-debug-apk
\`\`\`
README_TPL
else
  # Append cloud build instructions if not present
  if ! grep -q "Cloud Gradle APK Compilation" "$TARGET_DIR/README.md"; then
    cat << 'README_APPEND' >> "$TARGET_DIR/README.md"

---

## 🤖 Cloud Gradle APK Compilation (Capacitor)
This repository is configured with an automated GitHub Actions workflow (`.github/workflows/build-apk.yml`) that compiles an Android APK in the cloud using Gradle. See [FOLDER_ORGANIZATION.md](FOLDER_ORGANIZATION.md) for full architectural guidelines.

```bash
# Trigger build manually via GitHub CLI
gh workflow run build-apk.yml

# Download compiled APK
gh run download --name app-debug-apk
```
README_APPEND
  fi
fi

# ------------------------------------------------------------------------------
# Step 6: Generate All-in-One Code Digest (REPO_ALL_IN_ONE.txt)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[6/7] Generating All-in-One Code Digest with AI Prompt...${NC}"

AI_PROMPT='Act as an expert mobile developer and project organizer. Review the provided repository files and restructure the project layout into a clean, minimal, and scalable offline-first Capacitor architecture. Group all web source assets into a dedicated src/ directory with explicit subfolders for CSS (src/css/) and JavaScript (src/js/), ensuring index.html remains the primary offline entry point at the root of src/. Verify that the capacitor.config.json correctly targets src as its webDir. Finally, generate a comprehensive, clear README.md and FOLDER_ORGANIZATION.md that explicitly maps out this directory hierarchy and outlines how the automated GitHub Actions workflow compiles the project into an Android APK.'

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

echo -e "${GREEN}✓ Digest successfully written to:${NC} ${BOLD}REPO_ALL_IN_ONE.txt${NC}"

# ------------------------------------------------------------------------------
# Step 7: Git Commit, Push & Optional Workflow Trigger
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[7/7] Committing and pushing changes to GitHub...${NC}"

cd "$TARGET_DIR"
git add .
if git diff-index --quiet HEAD --; then
  echo "No changes needed to commit."
else
  git commit -m "feat(capacitor): configure offline src layout, cloud Gradle build, and organization docs"
  echo "Pushing to origin $CURRENT_BRANCH..."
  git push origin "$CURRENT_BRANCH"
  echo -e "${GREEN}✓ Changes successfully pushed to GitHub!${NC}"
fi

echo -e "\n${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Installation Complete!${NC}"
echo -e "Target: ${BOLD}${SELECTED_REPO:-$TARGET_DIR}${NC}"
echo -e "• Offline web source:  ${CYAN}src/ (index.html, css/, js/)${NC}"
echo -e "• Cloud Gradle CI:     ${CYAN}.github/workflows/build-apk.yml${NC}"
echo -e "• Layout Guide:        ${CYAN}FOLDER_ORGANIZATION.md${NC}"
echo -e "• All-in-One Digest:   ${CYAN}REPO_ALL_IN_ONE.txt${NC}"
echo -e "${BOLD}================================================================${NC}\n"

if [ "$IS_LOCAL" = false ]; then
  read -rp "Would you like to trigger the Cloud APK build right now? [y/N]: " run_now
  if [[ "$run_now" =~ ^[Yy]$ ]]; then
    echo -e "Triggering GitHub Actions workflow..."
    gh workflow run build-apk.yml --repo "$SELECTED_REPO"
    echo -e "${GREEN}✓ Workflow dispatched!${NC}"
    echo -e "To view progress, run: ${CYAN}gh run list --repo $SELECTED_REPO${NC}"
    echo -e "To download the APK when finished: ${CYAN}gh run download --repo $SELECTED_REPO -n app-debug-apk${NC}"
  fi
fi
