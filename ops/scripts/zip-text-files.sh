#!/usr/bin/env bash
# Zip all text/code files in the repository for AI review
# Excludes binary assets, images, 3D models, audio, caches, and secrets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

OUTPUT_FILE="${1:-$REPO_ROOT/southvale_text_files_$(date +%Y%m%d_%H%M%S).zip}"

echo "=== Packaging Text Files for AI ==="
echo "Repository root : $REPO_ROOT"
echo "Target archive  : $OUTPUT_FILE"

cd "$REPO_ROOT"

# Use zip with inclusions for text files and exclusions for caches, binaries, secrets, git
zip -r -q "$OUTPUT_FILE" . \
    -i "*.lua" "*.js" "*.mjs" "*.cjs" "*.ts" "*.tsx" "*.jsx" \
       "*.json" "*.cfg" "*.sql" "*.md" "*.html" "*.htm" "*.css" "*.scss" \
       "*.yml" "*.yaml" "*.ps1" "*.sh" "*.txt" "*.xml" "*.ini" "*.editorconfig" \
       "*.gitignore" "*.gitattributes" "LICENSE" \
    -x ".git/*" "cache/*" "txData/*" "db/*" "node_modules/*" "backups/*" ".vscode/*" \
       "*.log" "*.png" "*.jpg" "*.jpeg" "*.webp" "*.dds" "*.ytd" "*.ydr" "*.yft" "*.ybn" \
       "*.zip" "*.tar" "*.gz" "*.xz" "*.dll" "*.exe" "*.so" "*secrets.cfg*" "*.env*"

ZIP_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
FILE_COUNT=$(unzip -l "$OUTPUT_FILE" | tail -n 1 | awk '{print $2}')

echo -e "\n[SUCCESS] Archive created successfully!"
echo "Total text files archived : $FILE_COUNT"
echo "Compressed archive size   : $ZIP_SIZE"
echo "Archive location          : $OUTPUT_FILE"
