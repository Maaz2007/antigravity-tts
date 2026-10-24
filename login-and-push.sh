#!/usr/bin/env bash
# ==============================================================================
# Browser Login & Push Helper for Antigravity TTS
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo "        GitHub Browser Login & Instant Push               "
echo "=========================================================="
echo ""

# Ensure gh is in PATH
export PATH="$HOME/.local/bin:$PATH"

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) not found in ~/.local/bin."
    exit 1
fi

echo "[1/3] Starting GitHub Browser Login..."
echo "A one-time code will appear below and your browser will open."
echo "Simply paste the code into your browser and click Authorize."
echo ""

gh auth login --web -h github.com -p https

echo ""
echo "[2/3] Configuring Git credentials..."
gh auth setup-git

echo ""
echo "[3/3] Pushing to https://github.com/Maaz2007/antigravity-tts..."
git push -u origin main

echo ""
echo "=========================================================="
echo "🎉 SUCCESS! Code has been pushed to your GitHub:"
echo "👉 https://github.com/Maaz2007/antigravity-tts"
echo "=========================================================="
