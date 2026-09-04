# ⚡ Termux Capacitor & Cloud Gradle Workflow Installer

A fully automated, remote installer built for **Android Termux** and Linux terminal environments. It transforms any selected GitHub repository into an **offline-first Capacitor application** equipped with an automated **GitHub Actions Cloud Gradle APK builder**, complete directory organization docs, and a single-file codebase digest with an embedded AI prompt.

---

## 🚀 One-Line Termux Quickstart

Run the installer directly inside **Termux** (or any bash terminal) using `curl`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AllensCreations/termux-capacitor-cloud-installer/main/installer.sh)
```

*(Or clone this repository and run `./installer.sh` locally)*.

---

## 🎯 What the Installer Does

1. **Dependency Verification:** Automatically verifies/installs `gh`, `jq`, `git`, and `curl` via `pkg` (Termux) or `apt`.
2. **GitHub CLI Authentication:** Ensures you are logged in via `gh auth login`.
3. **Interactive Repo Selector:** Displays a numbered menu of your GitHub repositories to choose from.
4. **Offline-First Restructuring:**
   - Establishes a dedicated `src/` directory.
   - Moves/creates `src/index.html` as the primary offline entry point.
   - Groups stylesheets into `src/css/` and scripts into `src/js/`.
5. **Capacitor Configuration:** Configures `capacitor.config.json` with `"webDir": "src"`.
6. **Cloud Gradle Build CI (`build-apk.yml`):**
   - Installs `.github/workflows/build-apk.yml`.
   - Compiles native Android APKs on GitHub's fast Ubuntu runners (`./gradlew assembleDebug`).
   - Keeps your phone 100% free from gigabytes of heavy Android SDKs and Java Gradle daemons.
7. **Comprehensive Documentation:** Injects `FOLDER_ORGANIZATION.md` and updates `README.md`.
8. **All-in-One Code Digest (`REPO_ALL_IN_ONE.txt`):**
   - Pre-pends your expert mobile developer AI prompt.
   - Generates directory hierarchy.
   - Concatenates clean source files into a single context document ready to feed to an LLM.
9. **Git Commit & Cloud Build Trigger:** Pushes changes to GitHub and can immediately dispatch the build workflow.

---

## 📲 Downloading the Built APK to Your Phone

Once GitHub Actions finishes compiling your APK:

```bash
# 1. Check workflow status
gh run list --workflow=build-apk.yml

# 2. Download the APK
gh run download -n app-debug-apk

# 3. Move to Android Download folder (in Termux)
mv app-debug.apk /sdcard/Download/
```

---

## 📂 Repository Structure

```
termux-capacitor-cloud-installer/
├── installer.sh                      # Master interactive curl/Termux installer
├── templates/
│   ├── .github/workflows/build-apk.yml  # Cloud Gradle CI workflow template
│   ├── capacitor.config.json            # Base Capacitor configuration template
│   ├── FOLDER_ORGANIZATION.md           # Architectural & layout documentation
│   └── README.md                        # Target repository README template
└── scripts/
    └── generate_digest.sh               # Standalone digest flattener + prompt prepender
```
