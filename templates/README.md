# Mobile Web App (Capacitor + Cloud Gradle Builder)

An offline-first mobile application structured for **Capacitor** with automated **GitHub Actions Gradle APK compilation**.

---

## 🚀 Quick Start & Development

- **Web Source:** All client code lives in `src/`.
- **Offline Entrypoint:** `src/index.html`
- **Styles:** `src/css/style.css`
- **Scripts:** `src/js/app.js`

For full details on the directory hierarchy and architecture decisions, see [FOLDER_ORGANIZATION.md](FOLDER_ORGANIZATION.md).

---

## 🤖 Cloud Gradle APK Compilation

You do **not** need to install heavy Android SDKs or Gradle locally. Every push to the repository automatically triggers the GitHub Actions workflow to build the Android APK.

### Trigger Build Manually (Termux or Terminal)
```bash
gh workflow run build-apk.yml
```

### Download the Compiled APK
```bash
# List recent build runs
gh run list --workflow=build-apk.yml

# Download the latest artifact
gh run download --name app-debug-apk

# (On Android Termux) Move to your storage
mv app-debug.apk /sdcard/Download/
```

---

## 🧠 AI Prompt & Codebase Digest

A complete digest of the project with an embedded LLM prompt is available in `REPO_ALL_IN_ONE.txt`. You can pass this file directly into an AI assistant for architecture reviews, feature additions, or debugging.
