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
gh_user=$(gh api user -q .login 2>/dev/null || true)
if [ -z "$gh_user" ] || [ "$gh_user" = "user" ]; then
  gh_user=$(gh auth status 2>&1 | grep -oE "account [a-zA-Z0-9_-]+" | head -n1 | awk '{print $2}' || true)
fi
if [ -z "$gh_user" ]; then
  read -rp "Enter your GitHub username: " gh_user
fi
echo -e "      ${GREEN}✓ Logged in as:${NC} ${BOLD}${gh_user}${NC}"

# ------------------------------------------------------------------------------
# Step 3: Action Selection
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/6] 🎯 Choose Setup Mode:${NC}\n"
echo -e "  ${GREEN}${BOLD}[1] 🌟 Create a Brand New Clean Repository (Recommended)${NC}"
echo -e "      Scaffolds pristine offline-first app, AI instructions, Google Play guide, and Cloud Gradle CI."
echo -e "  ${CYAN}[2] 📂 Configure an Existing Repository from GitHub${NC}"
echo -e "      Injects Capacitor, Cloud Gradle CI, and generates an AI Migration & Fix Digest to avoid breaking."
echo -e "  ${YELLOW}[3] 💻 Configure an Existing Local Folder${NC}"
echo -e "      Configures a local folder and generates a safe AI Migration Digest."

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
  REPO_DESC="${REPO_DESC:-Offline-first Capacitor app with Cloud Gradle CI & Auto-Releases}"

  DEST_DIR="$(pwd)/$NEW_REPO_NAME"
  if [ -d "$DEST_DIR" ]; then
    echo -e "      ${YELLOW}Local directory ./${NEW_REPO_NAME} already exists.${NC}"
  else
    mkdir -p "$DEST_DIR"
  fi

  echo -e "\nCreating GitHub repository ${CYAN}${gh_user}/${NEW_REPO_NAME}${NC}..."
  if gh repo view "${gh_user}/${NEW_REPO_NAME}" >/dev/null 2>&1; then
    echo -e "      ${YELLOW}Remote repository ${gh_user}/${NEW_REPO_NAME} already exists on GitHub. Linking...${NC}"
  else
    if ! gh repo create "$NEW_REPO_NAME" "--$REPO_VIS" --description "$REPO_DESC"; then
      echo -e "      ${RED}Failed to create repository ${gh_user}/${NEW_REPO_NAME} on GitHub.${NC}"
      exit 1
    fi
    echo -e "      ${GREEN}✓ Created remote repository on GitHub: ${gh_user}/${NEW_REPO_NAME}${NC}"
  fi

  cd "$DEST_DIR"
  if [ ! -d ".git" ]; then
    git init -b main 2>/dev/null || { git init && git checkout -B main 2>/dev/null || true; }
  fi
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${gh_user}/${NEW_REPO_NAME}.git"

  SELECTED_REPO="${gh_user}/${NEW_REPO_NAME}"
  TARGET_DIR="$DEST_DIR"

elif [ "$mode_choice" = "2" ]; then
  echo -e "\nFetching your GitHub repositories..."
  mapfile -t repos < <(gh repo list --limit 30 --json nameWithOwner,isPrivate,description --jq '.[] | "\(.nameWithOwner)\t\(if .isPrivate then "[Private]" else "[Public]" end)\t\(.description // "")"')
  
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

  repo_folder="${SELECTED_REPO##*/}"
  if [ "$(basename "$(pwd)")" = "$repo_folder" ] && [ -d ".git" ]; then
    TARGET_DIR="$(pwd)"
    echo -e "      ${GREEN}✓ Using current repository directory:${NC} $TARGET_DIR"
  elif [ -d "$(pwd)/$repo_folder/.git" ]; then
    TARGET_DIR="$(pwd)/$repo_folder"
    echo -e "      ${GREEN}✓ Found existing local clone in:${NC} $TARGET_DIR"
  else
    TARGET_DIR="$(pwd)/$repo_folder"
    echo -e "\nCloning ${SELECTED_REPO} into ${TARGET_DIR}..."
    git clone "https://github.com/$SELECTED_REPO.git" "$TARGET_DIR"
  fi

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
# Step 4: Scaffold UI & Offline-First src/ Architecture (Non-Destructive for Existing Repos)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/6] 📁 Structuring offline-first architecture (src/)...${NC}"

mkdir -p "$TARGET_DIR/src/css" "$TARGET_DIR/src/js" "$TARGET_DIR/src/assets" "$TARGET_DIR/assets"

if [ "$IS_NEW_REPO" = true ]; then
  # Stage starter 512x512 app icon
  if [ -f "$SCRIPT_DIR/templates/assets/icon.png" ]; then
    cp -f "$SCRIPT_DIR/templates/assets/icon.png" "$TARGET_DIR/assets/icon.png" 2>/dev/null || true
    cp -f "$SCRIPT_DIR/templates/assets/icon.png" "$TARGET_DIR/src/assets/icon.png" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import zlib, struct
w, h = 512, 512
raw = bytearray()
for y in range(h):
    raw.append(0)
    for x in range(w):
        dx, dy = x - 256, y - 256
        dist = (dx*dx + dy*dy)**0.5
        if dist < 240:
            if dist > 230:
                raw.extend([56, 189, 248, 255])
            elif (abs(dx) < 30 and abs(dy) < 140) or (abs(dy) < 30 and abs(dx) < 140):
                raw.extend([245, 158, 11, 255])
            else:
                raw.extend([15, 23, 42, 255])
        else:
            raw.extend([0, 0, 0, 0])
compressed = zlib.compress(bytes(raw), 9)
def chunk(tag, data):
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) + chunk(b'IDAT', compressed) + chunk(b'IEND', b'')
with open('$TARGET_DIR/assets/icon.png', 'wb') as f:
    f.write(png)
with open('$TARGET_DIR/src/assets/icon.png', 'wb') as f:
    f.write(png)
" 2>/dev/null || true
  fi

  # Brand new repository starter UI
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

  cat << 'CSS' > "$TARGET_DIR/src/css/style.css"
:root {
  --bg-color: #0d1117;
  --surface-color: #161b22;
  --border-color: #30363d;
  --primary-color: #2ea043;
  --text-main: #f0f6fc;
  --text-muted: #8b949e;
}
* { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; touch-action: manipulation; }
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

else
  # EXISTING REPO: Safe non-destructive linking and bidirectional staging
  echo -e "      ${YELLOW}⚠️ Preserving existing repository code without breaking...${NC}"
  mkdir -p "$TARGET_DIR/src/css" "$TARGET_DIR/src/js" "$TARGET_DIR/src/assets"
  [ -f "$TARGET_DIR/index.html" ] && cp -f "$TARGET_DIR/index.html" "$TARGET_DIR/src/index.html"
  [ -f "$TARGET_DIR/style.css" ] && cp -f "$TARGET_DIR/style.css" "$TARGET_DIR/src/style.css" && cp -f "$TARGET_DIR/style.css" "$TARGET_DIR/src/css/style.css"
  [ -d "$TARGET_DIR/css" ] && cp -rf "$TARGET_DIR/css/"* "$TARGET_DIR/src/css/" 2>/dev/null || true
  [ -f "$TARGET_DIR/app.js" ] && cp -f "$TARGET_DIR/app.js" "$TARGET_DIR/src/app.js"
  [ -d "$TARGET_DIR/js" ] && cp -rf "$TARGET_DIR/js" "$TARGET_DIR/src/" 2>/dev/null || true
  [ -f "$TARGET_DIR/turso.js" ] && cp -f "$TARGET_DIR/turso.js" "$TARGET_DIR/src/turso.js"
  [ -f "$TARGET_DIR/sw.js" ] && cp -f "$TARGET_DIR/sw.js" "$TARGET_DIR/src/sw.js"
  [ -f "$TARGET_DIR/manifest.json" ] && cp -f "$TARGET_DIR/manifest.json" "$TARGET_DIR/src/manifest.json"
  [ -f "$TARGET_DIR/version.json" ] && cp -f "$TARGET_DIR/version.json" "$TARGET_DIR/src/version.json"

  # Bidirectional fallback: ensure root has index.html and style.css for web hosting/Vercel
  if [ -f "$TARGET_DIR/src/css/style.css" ] && [ ! -f "$TARGET_DIR/style.css" ]; then
    cp -f "$TARGET_DIR/src/css/style.css" "$TARGET_DIR/style.css"
    cp -f "$TARGET_DIR/src/css/style.css" "$TARGET_DIR/src/style.css"
  fi
  if [ -f "$TARGET_DIR/src/index.html" ] && [ ! -f "$TARGET_DIR/index.html" ]; then
    cp -f "$TARGET_DIR/src/index.html" "$TARGET_DIR/index.html"
  fi

  # Bidirectional icon staging & fallback
  mkdir -p "$TARGET_DIR/assets" "$TARGET_DIR/src/assets"
  if [ -f "$TARGET_DIR/assets/icon.png" ]; then
    cp -f "$TARGET_DIR/assets/icon.png" "$TARGET_DIR/src/assets/icon.png" 2>/dev/null || true
  elif [ -f "$TARGET_DIR/icon.png" ]; then
    cp -f "$TARGET_DIR/icon.png" "$TARGET_DIR/assets/icon.png" 2>/dev/null || true
    cp -f "$TARGET_DIR/icon.png" "$TARGET_DIR/src/assets/icon.png" 2>/dev/null || true
  elif [ -f "$TARGET_DIR/src/assets/icon.png" ]; then
    cp -f "$TARGET_DIR/src/assets/icon.png" "$TARGET_DIR/assets/icon.png" 2>/dev/null || true
  else
    if [ -f "$SCRIPT_DIR/templates/assets/icon.png" ]; then
      cp -f "$SCRIPT_DIR/templates/assets/icon.png" "$TARGET_DIR/assets/icon.png" 2>/dev/null || true
      cp -f "$SCRIPT_DIR/templates/assets/icon.png" "$TARGET_DIR/src/assets/icon.png" 2>/dev/null || true
    fi
  fi
fi

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
# Step 5: Inject Capacitor Config, CI Workflow with Auto-Release & Guides
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[5/6] ⚙️ Injecting Capacitor config, Auto-Release workflow & Store docs...${NC}"

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
  },
  "plugins": {
    "SplashScreen": {
      "launchShowDuration": 0,
      "launchAutoHide": true,
      "launchFadeOutDuration": 0,
      "backgroundColor": "#0d1117",
      "androidSplashResourceName": "splash",
      "androidScaleType": "CENTER_CROP",
      "showSpinner": false,
      "splashFullScreen": true,
      "splashImmersive": true
    }
  }
}
CAPCONFIG

# 2. .github/workflows/build-apk.yml (Includes Softprops Auto-Release & AAB)
mkdir -p "$TARGET_DIR/.github/workflows"
cat << 'WORKFLOW' > "$TARGET_DIR/.github/workflows/build-apk.yml"
name: Build Android APK & Publish Release (Capacitor + Gradle)

on:
  push:
    branches: [ main, master, Version2 ]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build-and-release:
    name: Cloud Capacitor, Gradle & Release Publisher
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout Repository
        uses: actions/checkout@v4

      - name: ☕ Set up Java JDK 21 (Temurin)
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

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
          npm install --save @capacitor/core @capacitor/cli @capacitor/android @capacitor/splash-screen

      - name: 🛠️ Stage Web Assets into src/
        run: |
          mkdir -p src src/css src/js src/assets assets
          cp -rf index.html style.css app.js js turso.js sw.js manifest.json version.json assets src/ 2>/dev/null || true
          if [ -f style.css ]; then
            cp -f style.css src/style.css 2>/dev/null || true
            cp -f style.css src/css/style.css 2>/dev/null || true
          elif [ -f src/css/style.css ]; then
            cp -f src/css/style.css src/style.css 2>/dev/null || true
          elif [ -f src/style.css ]; then
            cp -f src/style.css src/css/style.css 2>/dev/null || true
          fi
          if [ ! -f index.html ] && [ -f src/index.html ]; then
            cp -f src/index.html index.html
          fi
          # Bidirectional icon staging
          if [ -f "assets/icon.png" ]; then
            cp -f assets/icon.png src/assets/icon.png 2>/dev/null || true
          elif [ -f "icon.png" ]; then
            cp -f icon.png assets/icon.png 2>/dev/null || true
            cp -f icon.png src/assets/icon.png 2>/dev/null || true
          elif [ -f "src/assets/icon.png" ]; then
            cp -f src/assets/icon.png assets/icon.png 2>/dev/null || true
          fi

      - name: ⚡ Initialize Android Platform & Sync Web Assets
        run: |
          if [ ! -d "android" ]; then
            npx cap add android
          fi
          npx cap sync android
          if ! grep -q "kotlin-stdlib-jdk8:1.8.22" android/app/build.gradle 2>/dev/null; then
            echo "" >> android/app/build.gradle
            echo "dependencies {" >> android/app/build.gradle
            echo "    constraints {" >> android/app/build.gradle
            echo '        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22")' >> android/app/build.gradle
            echo '        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22")' >> android/app/build.gradle
            echo "    }" >> android/app/build.gradle
            echo "}" >> android/app/build.gradle
          fi

      - name: 🎨 Generate Android App Icons & Remove Launch Splash Delay
        run: |
          # 1. Locate primary app icon
          ICON_SRC=""
          if [ -f "assets/icon.png" ]; then
            ICON_SRC="assets/icon.png"
          elif [ -f "icon.png" ]; then
            ICON_SRC="icon.png"
          elif [ -f "src/assets/icon.png" ]; then
            ICON_SRC="src/assets/icon.png"
          fi

          # 2. Automatically generate all Android launcher mipmap icons if icon exists
          if [ -n "$ICON_SRC" ] && [ -d "android/app/src/main/res" ]; then
            echo "🎨 Found app icon at $ICON_SRC. Generating Android mipmap launcher icons..."
            densities=("mdpi:48" "hdpi:72" "xhdpi:96" "xxhdpi:144" "xxxhdpi:192")
            for entry in "${densities[@]}"; do
              density="${entry%%:*}"
              size="${entry##*:}"
              target_dir="android/app/src/main/res/mipmap-${density}"
              mkdir -p "$target_dir"
              convert "$ICON_SRC" -resize "${size}x${size}" "$target_dir/ic_launcher.png" 2>/dev/null || true
              convert "$ICON_SRC" -resize "${size}x${size}" "$target_dir/ic_launcher_round.png" 2>/dev/null || true
              convert "$ICON_SRC" -resize "${size}x${size}" "$target_dir/ic_launcher_foreground.png" 2>/dev/null || true
            done

            mkdir -p src/assets
            cp -f "$ICON_SRC" src/assets/icon.png 2>/dev/null || true
            convert "$ICON_SRC" -resize 192x192 src/icon-192.png 2>/dev/null || true
            convert "$ICON_SRC" -resize 512x512 src/icon-512.png 2>/dev/null || true
            echo "✓ App icons generated for all densities."
          fi

          # 3. Completely remove popup splash icon delay on cold launch
          for splash_file in android/app/src/main/res/drawable/splash.xml android/app/src/main/res/drawable-v24/splash.xml; do
            if [ -f "$splash_file" ]; then
              printf '<?xml version="1.0" encoding="utf-8"?>\n<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n    <item android:drawable="@color/splashBackground"/>\n</layer-list>\n' > "$splash_file"
            fi
          done
          echo "✓ Removed splash popup icon; instant 0ms app launch configured."

      - name: 🐘 Compile APK & App Bundle (AAB) with Gradle
        run: |
          cd android
          chmod +x gradlew
          echo "Building debug APK for phone installation..."
          ./gradlew assembleDebug --stacktrace
          echo "Building Android App Bundle (.aab) for Google Play..."
          ./gradlew bundleDebug --stacktrace || true

      - name: 🏷️ Package Binaries with (RepoName-Version) Naming
        run: |
          REPO_NAME="${GITHUB_REPOSITORY##*/}"
          VERSION_TAG="v1.0.${{ github.run_number }}"
          mkdir -p release-assets

          # Copy and rename APK to RepoName-Version.apk
          APK_SRC="android/app/build/outputs/apk/debug/app-debug.apk"
          if [ -f "$APK_SRC" ]; then
            CUSTOM_APK="release-assets/${REPO_NAME}-${VERSION_TAG}.apk"
            cp -f "$APK_SRC" "$CUSTOM_APK"
            echo "✓ Packaged APK: $CUSTOM_APK"
          fi

          # Copy and rename AAB to RepoName-Version.aab
          AAB_SRC="android/app/build/outputs/bundle/debug/app-debug.aab"
          if [ -f "$AAB_SRC" ]; then
            CUSTOM_AAB="release-assets/${REPO_NAME}-${VERSION_TAG}.aab"
            cp -f "$AAB_SRC" "$CUSTOM_AAB"
            echo "✓ Packaged AAB: $CUSTOM_AAB"
          fi

      - name: 📤 Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: app-binaries
          path: release-assets/*
          retention-days: 14

      - name: 🚀 Auto-Publish to GitHub Releases
        uses: softprops/action-gh-release@v2
        if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master' || github.ref == 'refs/heads/Version2'
        with:
          tag_name: v1.0.${{ github.run_number }}
          name: Release v1.0.${{ github.run_number }} (Android APK & Bundle)
          body: |
            ## 📱 New Android Release Compiled via Cloud Gradle!
            
            This release contains compiled binaries built from commit `${{ github.sha }}`.

            ### 📦 Direct Downloads:
            - **Installable APK (`.apk`):** Download and install directly on your Android phone or Termux.
            - **Google Play App Bundle (`.aab`):** Formatted for Google Play Console distribution.

            ---

            ### 📋 Google Play Store Publishing Checklist
            *See `GOOGLE_PLAY_STORE_GUIDE.md` in this repository for complete documentation.*

            1. **Developer Account:** Paid $25 registration fee & completed government ID / DUNS verification.
            2. **App Format:** Standard format is Android App Bundle (`.aab`) under 200MB.
            3. **Digital Signing:** Enrolled in Play App Signing with your release keystore.
            4. **Version Code:** Increment `versionCode` in `android/app/build.gradle` for every release upload.
            5. **Store Assets:** 512x512 icon, 1024x500 feature graphic, 2+ screenshots, and HTTPS Privacy Policy URL.
            6. **Closed Testing:** 20 testers for at least 14 continuous days (for accounts created after Nov 2023).
          files: release-assets/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
WORKFLOW

# 2b. .github/workflows/deploy-pages.yml (Instant Live Web Preview on GitHub Pages)
cat << 'PAGES_WF' > "$TARGET_DIR/.github/workflows/deploy-pages.yml"
name: Deploy Live Web Preview (GitHub Pages)

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy-pages:
    name: 🌐 Deploy src/ to GitHub Pages
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout Repository
        uses: actions/checkout@v4

      - name: 🛠️ Setup Pages
        uses: actions/configure-pages@v5

      - name: 📦 Stage & Upload Web Artifacts (src/)
        uses: actions/upload-pages-artifact@v3
        with:
          path: 'src'

      - name: 🚀 Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
PAGES_WF

# 2c. .github/workflows/audit-mobile.yml (Relative Path Guard & White Blank Screen Prevention)
cat << 'AUDIT_WF' > "$TARGET_DIR/.github/workflows/audit-mobile.yml"
name: Audit Mobile Compatibility & Relative Paths

on:
  push:
    branches: [ main, master ]
  pull_request:

jobs:
  lint-mobile:
    name: 🛡️ Mobile Guard & Relative Path Check
    runs-on: ubuntu-latest
    steps:
      - name: 📥 Checkout Repository
        uses: actions/checkout@v4

      - name: 🔍 Scan for Breaking Absolute Root Paths
        run: |
          echo "Scanning for root-leading paths (/css, /js, /assets) in web source..."
          ERRORS=0
          if grep -rnE '(src|href)=["'"'"']/([a-zA-Z0-9_-]+)' src/ 2>/dev/null; then
            echo "::error::Found absolute root paths above! In Android WebViews, use strictly relative paths (e.g., 'css/style.css' instead of '/css/style.css')."
            ERRORS=$((ERRORS + 1))
          else
            echo "✓ Zero broken root paths found in src/."
          fi
          exit $ERRORS

      - name: 📋 Validate JSON Configuration Files
        run: |
          node -e "
          const fs = require('fs');
          const files = ['manifest.json', 'src/manifest.json', 'capacitor.config.json', 'package.json'];
          for (const f of files) {
            if (fs.existsSync(f)) {
              try {
                JSON.parse(fs.readFileSync(f, 'utf8'));
                console.log('✓ ' + f + ' is valid JSON');
              } catch (e) {
                console.error('::error file=' + f + '::Invalid JSON: ' + e.message);
                process.exit(1);
              }
            }
          }
          "
AUDIT_WF

# 2d. .github/workflows/clean-artifacts.yml (Actions Storage Quota Cleaner)
cat << 'CLEAN_WF' > "$TARGET_DIR/.github/workflows/clean-artifacts.yml"
name: Cleanup Old Build Artifacts

on:
  schedule:
    - cron: '0 0 * * 0'
  workflow_dispatch:

permissions:
  actions: write

jobs:
  prune-artifacts:
    name: 🧹 Prune Old Workflow Artifacts
    runs-on: ubuntu-latest
    steps:
      - name: 🧹 Delete Artifacts Older than 14 Days
        uses: c-hive/gha-remove-artifacts@v1
        with:
          age: '14 days'
          skip-recent: 5
CLEAN_WF

# 3. AI_INSTRUCTIONS.md
cat << 'AI_DOC' > "$TARGET_DIR/AI_INSTRUCTIONS.md"
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
- All outputs are packaged and tagged as **`<RepoName>-<Version>.apk`** and **`<RepoName>-<Version>.aab`** (e.g. `FightingLightsV-v1.0.35.apk`).

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
AI_DOC

# 4. GOOGLE_PLAY_STORE_GUIDE.md
cat << 'PLAY_DOC' > "$TARGET_DIR/GOOGLE_PLAY_STORE_GUIDE.md"
# 📱 Google Play Store Publishing & Technical Requirements Guide

This comprehensive guide outlines all administrative, technical, and policy prerequisites required to publish and maintain an Android app on the Google Play Store.

---

## 1. 🏢 Developer Account Requirements

* **Google Play Developer Account Registration:**
  * Must register at the [Google Play Console](https://play.google.com/console).
  * Pay a **one-time registration fee of $25 USD**.
* **Identity Verification:**
  * **Individual Accounts:** Government-issued photo ID (passport, driver's license) and address verification.
  * **Organization/Business Accounts:** Valid **D-U-N-S Number** (Dun & Bradstreet), official organization documentation, and authorized representative verification.

---

## 2. ⚙️ Technical & File Requirements

* **Standard App Format (Android App Bundle - `.aab`):**
  * Google Play requires new apps to be uploaded as **Android App Bundles (`.aab`)**, not traditional `.apk` files.
  * Google's dynamic delivery system uses the `.aab` to generate optimized APKs tailored to each user's device configuration (screen density, CPU architecture, language).
* **Digital Cryptographic Signature:**
  * The release bundle must be digitally signed with a cryptographic private key.
  * Command to generate a release keystore:
    ```bash
    keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-app-key
    ```
* **Play App Signing:**
  * Enrollment in **Google Play App Signing** is required.
  * Google manages and securely protects your app's signing key on its infrastructure and uses it to sign APKs delivered to users.
* **Target API Level:**
  * Must target the recent Android API level mandated by Google Play policies (typically Android 14 / API 34+ or higher).
* **Incrementing Version Code (`versionCode`):**
  * Every new release uploaded to the Play Console must have a **strictly higher integer `versionCode`** than the previous build (e.g., `1`, `2`, `3`).
  * In Capacitor/Android, this is configured in `android/app/build.gradle`:
    ```groovy
    defaultConfig {
        versionCode 2
        versionName "1.0.1"
    }
    ```
* **Download Size Limits:**
  * The maximum compressed download size for individual APKs generated from bundles is **200 MB**.
  * Apps requiring larger asset footprints must implement Play Feature Delivery or Play Asset Delivery.

---

## 3. 🎨 Store Listing & Policy Prerequisites

* **Store Listing Assets:**
  * **App Name:** Up to 30 characters.
  * **Short Description:** Up to 80 characters.
  * **Full Description:** Up to 4,000 characters.
  * **High-Resolution App Icon:** Exactly `512 x 512 px`, 32-bit PNG, up to 1 MB.
  * **Feature Graphic:** Exactly `1024 x 500 px`, JPG or 24-bit PNG, no transparency.
  * **Screenshots:** Minimum of 2 phone screenshots (JPEG or 24-bit PNG, minimum 320px, maximum 3840px, 16:9 or 9:16 aspect ratio recommended).
* **Privacy Policy URL:**
  * A valid, publicly accessible HTTPS privacy policy URL is mandatory for all apps, especially if accessing device features, storage, or external APIs.
* **Content Rating & Policy Declarations:**
  * Complete the IARC Content Rating questionnaire in Play Console.
  * Submit mandatory declarations:
    * Target age and audience (COPPA compliance if targeting children under 13).
    * Ads declaration (indicate if app serves ads).
    * Data Safety section (disclose what user data is collected, stored, or shared).
    * Government apps / financial / health declarations (if applicable).

---

## 4. 🧪 Mandatory Closed Testing Requirement (Accounts Created After Nov 2023)

> [!IMPORTANT]
> If your Google Play Developer Account was created after **November 13, 2023**, Google requires you to run a **Closed Test** before applying for Production access:
> * **Minimum Testers:** At least **20 testers** must opt-in to your closed test.
> * **Duration:** Testers must be continuously opted-in for at least **14 consecutive days**.
> * Only after satisfying this period and gathering tester feedback can you apply for full production release access in Google Play Console.
PLAY_DOC

# 5. FOLDER_ORGANIZATION.md
cat << 'ORG_DOC' > "$TARGET_DIR/FOLDER_ORGANIZATION.md"
# Project Layout & Architecture Guide (Offline-First Capacitor)

```
├── assets/                            # 🎨 Source App Icons & Assets
│   └── icon.png                       # 🖼️ High-Res App Icon (512x512 PNG, auto-generated into all Android densities)
├── src/                               # 🌐 Web Assets & Application Core (Capacitor webDir)
│   ├── index.html                     # 🎯 Primary offline entry point
│   ├── css/                           # 🎨 Styling & stylesheets (style.css)
│   ├── js/                            # ⚙️ Application logic (app.js)
│   └── assets/                        # 🖼️ Offline icons, images, fonts (mirrored icon.png)
│
├── .github/workflows/
│   ├── build-apk.yml                  # 🤖 Cloud CI/CD: Gradle APK/AAB build + Auto-Renamer + Releases
│   ├── deploy-pages.yml               # 🌐 Live Web Preview deployed to GitHub Pages
│   ├── audit-mobile.yml               # 🛡️ Guard against breaking absolute paths & invalid JSON
│   └── clean-artifacts.yml            # 🧹 Storage pruner for old GitHub Actions artifacts
├── capacitor.config.json              # 📱 Capacitor native bridge (0ms instant splash configuration)
├── AI_INSTRUCTIONS.md                 # 🤖 AI assistant prompts & mobile rules
├── GOOGLE_PLAY_STORE_GUIDE.md         # 📱 Google Play requirements & publishing checklist
├── FOLDER_ORGANIZATION.md             # 📖 Architecture & layout blueprint
├── README.md                          # 🚀 Project documentation & APK download guide
└── REPO_ALL_IN_ONE.txt                # 🧠 Consolidated codebase digest with AI prompt
```
ORG_DOC

# 6. README.md
if [ ! -f "$TARGET_DIR/README.md" ]; then
  cat << README_DOC > "$TARGET_DIR/README.md"
# ${SELECTED_REPO##*/} (Offline-First Capacitor + Cloud Gradle + Auto-Releases)

An offline-first hybrid mobile app structured for **Capacitor** with automated **GitHub Actions Gradle APK/AAB compilation and GitHub Releases**.

---

## 🚀 Development & Structure
- **Web Source:** All client code lives in \`src/\`.
- **Entrypoint:** \`src/index.html\`
- **Styles:** \`src/css/style.css\`
- **Scripts:** \`src/js/app.js\`

See [FOLDER_ORGANIZATION.md](FOLDER_ORGANIZATION.md) for full directory specifications and [AI_INSTRUCTIONS.md](AI_INSTRUCTIONS.md) for AI-assisted development instructions.

---

## 🎨 Custom App Icon Placement
- Place your app icon at: **\`assets/icon.png\`** (or \`icon.png\` in root).
- Recommended size: **\`512x512 px\`** (PNG format).
- **Automated Density Generation:** Cloud CI automatically generates all Android launcher icons (\`mipmap-mdpi\`, \`hdpi\`, \`xhdpi\`, \`xxhdpi\`, \`xxxhdpi\`) including round and adaptive foreground variants, plus Web/PWA icons (\`src/icon-192.png\`, \`src/icon-512.png\`).

---

## ⚡ Instant App Launch (Zero Splash Screen Delay & 0ms Fast)
- Pre-configured with **\`"launchShowDuration": 0\`** and **\`"showSpinner": false\`** in \`capacitor.config.json\`.
- The app opens **immediately and smoothly (0ms)** without any loading icon popup or artificial delay.
- Smoothness means instant responsiveness and zero animation bloat—keeping the app fast on mobile and Termux.

---

## 🤖 Cloud Gradle APK/AAB Compilation & Releases
Every push to \`main\` automatically compiles both the Android APK and App Bundle (.aab) in GitHub Actions and publishes a **GitHub Release**:

- **Custom-Named Binaries:** Releases are named **\`${SELECTED_REPO##*/}-v1.0.<run_number>.apk\`** and **\`${SELECTED_REPO##*/}-v1.0.<run_number>.aab\`** (no generic \`app-debug.apk\`!).
- **Direct Download:** Check the **Releases** tab on GitHub to download the latest APK.
- **Play Store Requirements:** See [GOOGLE_PLAY_STORE_GUIDE.md](GOOGLE_PLAY_STORE_GUIDE.md) for the complete publishing checklist.
- **🌐 Live Web Preview:** Automatically deployed to GitHub Pages on every push.
README_DOC
else
  if ! grep -q "Cloud Gradle APK/AAB Compilation" "$TARGET_DIR/README.md"; then
    cat << 'README_APPEND' >> "$TARGET_DIR/README.md"

---

## 🎨 Custom App Icon Placement
- Place your app icon at: **`assets/icon.png`** (or `icon.png` in root).
- Automated CI generates all Android launcher icon densities (`mipmap-*`) and Web/PWA icons.

---

## ⚡ Instant App Launch (Zero Splash Delay)
- Configured with `"launchShowDuration": 0` in `capacitor.config.json` for 0ms instant, smooth startup without any popup icon delay.

---

## 🤖 Cloud Gradle APK/AAB Compilation & Releases
Every push automatically compiles the Android APK and App Bundle (.aab) in GitHub Actions and publishes a **GitHub Release**:
- **Releases Tab:** Download \`${SELECTED_REPO##*/}-v1.0.<run_number>.apk\` from your GitHub Releases page.
- **Store Rules:** See \`GOOGLE_PLAY_STORE_GUIDE.md\` for Google Play publishing rules.
README_APPEND
  fi
fi

# ------------------------------------------------------------------------------
# Step 6: Generate All-in-One Code Digest (Tailored for New vs Existing Repo)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[6/6] 🧠 Generating All-in-One Code Digest with AI Prompt...${NC}"

repo_name_only=$(basename "$SELECTED_REPO")

if [ "$IS_NEW_REPO" = true ]; then
  AI_PROMPT='Act as an expert mobile developer and project organizer. Review the provided repository files and develop the application following a clean, minimal, and scalable offline-first Capacitor architecture. Group all web source assets into a dedicated src/ directory with explicit subfolders for CSS (src/css/) and JavaScript (src/js/), ensuring index.html remains the primary offline entry point at the root of src/. Verify that the capacitor.config.json correctly targets src as its webDir. Ensure all paths in index.html are strictly relative, that offline storage (localStorage/IndexedDB) is utilized, adhere to Google Play Store requirements in GOOGLE_PLAY_STORE_GUIDE.md (e.g. versionCode incrementing and AAB format), and outline how the automated GitHub Actions workflow compiles the project into an Android APK via Gradle and automatically publishes GitHub Releases.'
  OUTPUT_DIGEST="$TARGET_DIR/${repo_name_only}_ALL_IN_ONE.txt"
else
  # SPECIALIZED EXISTING REPO MIGRATION PROMPT (Prevents breaking changes!)
  AI_PROMPT='Act as a Senior Principal Mobile Engineer and Codebase Migration Specialist. Review the provided existing repository files below and refactor the project layout into a clean, minimal, and scalable offline-first Capacitor architecture without breaking any existing functionality.

OBJECTIVE:
Analyze the full source code provided and output a non-destructive migration plan and exact file modifications to achieve 100% compatibility with Capacitor, Gradle APK/AAB builds, and Google Play Store policies.

STRICT CONSTRAINTS & AUDIT RULES:
1. ZERO BREAKING CHANGES:
   - Preserve all existing UI, business logic, state handling, routes, and feature behaviors.
   - Do not delete existing assets or change variable names unless necessary for mobile compatibility.

2. WEB ASSETS RESTRUCTURING (src/):
   - Group all client-facing web assets into a dedicated src/ directory (src/index.html, src/css/, src/js/, src/assets/).
   - Ensure capacitor.config.json correctly points to "webDir": "src".

3. STRICT RELATIVE PATH CONVERSION (CRITICAL):
   - In Android WebViews, absolute root paths (e.g. /style.css, /app.js, /images/logo.png) result in blank screens.
   - Convert all asset and script references in index.html, JS, and CSS to strictly relative paths (e.g. css/style.css, js/app.js, ./assets/logo.png).

4. FRONTEND / BACKEND DECOUPLING:
   - Identify any server-side runtime code (Node.js, Express, server.js, Cloudflare workers).
   - Ensure backend files remain outside of src/ so they are not bundled into the client APK.
   - If the frontend communicates with the backend, ensure full HTTPS URLs are used with graceful offline error handling.

5. OFFLINE-FIRST RESILIENCE:
   - Ensure the app can boot and render cleanly even if the user opens the app while in Airplane mode or without internet.
   - Use localStorage or IndexedDB for offline state storage.

6. GOOGLE PLAY & GRADLE READINESS:
   - Adhere to GOOGLE_PLAY_STORE_GUIDE.md (e.g. incremental versionCode in build.gradle, Android App Bundle .aab format).

OUTPUT FORMAT REQUIRED:
1. Audit Summary: Detailed list of potential breaking points found (absolute paths, server dependencies, missing offline handlers).
2. Refactored File Tree: Explicit layout of the restructured repository.
3. Code Replacements / Unified Diffs: Complete, drop-in replacement code for any modified files with exact filepaths.
4. Verification Instructions: How to test the refactored code both in a browser and as a compiled Android APK.'
  OUTPUT_DIGEST="$TARGET_DIR/${repo_name_only}_ALL_IN_ONE_FIX.txt"
fi

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

# Keep repo-named ALL_IN_ONE also available
if [ "$IS_NEW_REPO" = false ]; then
  cp "$OUTPUT_DIGEST" "$TARGET_DIR/${repo_name_only}_ALL_IN_ONE.txt"
fi

echo -e "      ${GREEN}✓ Digest created:${NC} ${BOLD}$(basename "$OUTPUT_DIGEST")${NC}"

# ------------------------------------------------------------------------------
# Git Commit, Push & Dispatch
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}🚀 Pushing project to GitHub...${NC}"
cd "$TARGET_DIR"
git add -A
if git status --porcelain | grep -q .; then
  git commit -m "feat: configure capacitor, cloud gradle CI, auto-releases, and AI migration context"
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
[ -z "$CURRENT_BRANCH" ] && CURRENT_BRANCH="main"

echo -e "      Pushing to origin/${CURRENT_BRANCH}..."
if ! git push -u origin "$CURRENT_BRANCH" 2>/dev/null; then
  echo -e "      ${YELLOW}Configuring Git credential helper and retrying...${NC}"
  gh auth setup-git 2>/dev/null || true
  git push -u origin "$CURRENT_BRANCH"
fi
echo -e "      ${GREEN}✓ Successfully pushed to GitHub!${NC}"

echo -e "\n${BOLD}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}🎉 SUCCESS! Installation Completed!${NC}"
echo -e "Repository:   ${CYAN}https://github.com/${SELECTED_REPO}${NC}"
echo -e "Local Folder: ${CYAN}${TARGET_DIR}${NC}"
echo -e "════════════════════════════════════════════════════════════════"

if [ "$IS_NEW_REPO" = true ]; then
  echo -e "✨ ${BOLD}New Repository Ready:${NC}"
  echo -e "   1. Open ${CYAN}${repo_name_only}_ALL_IN_ONE.txt${NC} or ${CYAN}AI_INSTRUCTIONS.md${NC}."
  echo -e "   2. Paste into ChatGPT, Claude, Gemini, or Antigravity to build features!\n"
else
  echo -e "🚨 ${YELLOW}${BOLD}EXISTING REPOSITORY CONFIGURED (MIGRATION SAFEGUARD):${NC}"
  echo -e "   To adapt your existing code without breaking relative links or features:"
  echo -e "   1. Open ${CYAN}${BOLD}${repo_name_only}_ALL_IN_ONE_FIX.txt${NC}"
  echo -e "   2. Copy and paste the entire file into ${BOLD}ChatGPT, Claude, Gemini, or Antigravity${NC}."
  echo -e "   3. The embedded AI prompt will audit your existing files, convert"
  echo -e "      absolute paths into relative paths, and guide your safe migration!\n"
fi

echo -e "📦 ${BOLD}Automated GitHub Releases:${NC}"
echo -e "   View & download compiled APKs at: ${CYAN}https://github.com/${SELECTED_REPO}/releases${NC}\n"

if [ "$IS_LOCAL" = false ]; then
  read -rp "Would you like to trigger the Cloud APK build right now? [y/N]: " run_now
  if [[ "$run_now" =~ ^[Yy]$ ]]; then
    echo -e "Triggering GitHub Actions workflow..."
    gh workflow run build-apk.yml --repo "$SELECTED_REPO"
    echo -e "${GREEN}✓ Workflow dispatched in the cloud!${NC}"
    echo -e "Track build:     ${CYAN}gh run list --repo $SELECTED_REPO${NC}"
    echo -e "Direct Download: ${CYAN}https://github.com/$SELECTED_REPO/releases${NC}"
  fi
fi
