#!/usr/bin/env bash
# ==============================================================================
# generate_digest.sh - Consolidated All-in-One Repo Digest Generator with AI Prompt
# ==============================================================================

set -euo pipefail

TARGET_DIR="${1:-.}"
OUTPUT_FILE="${2:-$TARGET_DIR/REPO_ALL_IN_ONE.txt}"
CUSTOM_PROMPT="${3:-}"

DEFAULT_PROMPT='Act as an expert mobile developer and project organizer. Review the provided repository files and restructure the project layout into a clean, minimal, and scalable offline-first Capacitor architecture. Group all web source assets into a dedicated src/ directory with explicit subfolders for CSS (src/css/) and JavaScript (src/js/), ensuring index.html remains the primary offline entry point at the root of src/. Verify that the capacitor.config.json correctly targets src as its webDir. Finally, generate a comprehensive, clear README.md and FOLDER_ORGANIZATION.md that explicitly maps out this directory hierarchy and outlines how the automated GitHub Actions workflow compiles the project into an Android APK.'

PROMPT="${CUSTOM_PROMPT:-$DEFAULT_PROMPT}"

echo "Generating codebase digest for: $TARGET_DIR"
echo "Output file: $OUTPUT_FILE"

# Prepare output file
rm -f "$OUTPUT_FILE"

cat << PROMPT_HEADER > "$OUTPUT_FILE"
================================================================================
AI SYSTEM & ARCHITECTURE PROMPT:
$PROMPT
================================================================================

PROJECT OVERVIEW & DIRECTORY TREE
Generated: $(date -u +"%Y-%m-%d %H:%M:%SZ")
Repository Path: $TARGET_DIR
--------------------------------------------------------------------------------
PROMPT_HEADER

# Generate directory tree
if command -v tree >/dev/null 2>&1; then
  tree -a -I '.git|node_modules|android|.gradle|.github|build|dist|.wrangler' "$TARGET_DIR" >> "$OUTPUT_FILE"
else
  # Fallback to find if tree is not installed
  (cd "$TARGET_DIR" && find . -maxdepth 4 -not -path '*/.*' -not -path './node_modules*' -not -path './android*' -not -path './.gradle*' | sort) >> "$OUTPUT_FILE"
fi

cat << SEPARATOR >> "$OUTPUT_FILE"

================================================================================
CONSOLIDATED SOURCE CODE FILES
================================================================================
SEPARATOR

# Find all relevant text files, excluding binaries and heavy folders
IGNORE_PATTERN="(\.git|\.gradle|android|node_modules|build|dist|\.wrangler|\.idea|\.vscode)"
BINARY_EXTENSIONS="png|jpg|jpeg|gif|svg|ico|webp|mp3|mp4|apk|aab|keystore|jar|zip|gz|tar|woff|woff2|ttf|eot|pdf"

find "$TARGET_DIR" -type f | while read -r filepath; do
  relpath="${filepath#$TARGET_DIR/}"
  
  # Skip output file itself
  if [ "$filepath" = "$OUTPUT_FILE" ]; then
    continue
  fi

  # Skip ignored directories
  if echo "$relpath" | grep -qE "$IGNORE_PATTERN"; then
    continue
  fi

  # Skip binary file extensions
  if echo "$relpath" | grep -qiE "\.($BINARY_EXTENSIONS)$"; then
    continue
  fi

  # Skip files larger than 1MB
  filesize=$(wc -c < "$filepath" 2>/dev/null || echo 0)
  if [ "$filesize" -gt 1048576 ]; then
    continue
  fi

  # Check if file is readable text
  if [ -r "$filepath" ]; then
    echo "Adding: $relpath"
    cat << FILE_BLOCK >> "$OUTPUT_FILE"

--------------------------------------------------------------------------------
FILE: $relpath
--------------------------------------------------------------------------------
FILE_BLOCK
    cat "$filepath" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  fi
done

echo "✅ All-in-One Digest created successfully at: $OUTPUT_FILE"
