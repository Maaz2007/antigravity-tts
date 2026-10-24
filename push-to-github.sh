#!/usr/bin/env bash
# ==============================================================================
# Helper to push Antigravity TTS to GitHub
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Checking remote configuration..."
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [[ -z "$REMOTE_URL" ]]; then
    git remote add origin "https://github.com/Maaz2007/antigravity-tts.git"
    REMOTE_URL="https://github.com/Maaz2007/antigravity-tts.git"
fi

echo "Remote URL: $REMOTE_URL"
echo "Pushing 'main' branch to GitHub..."

# Try pushing directly
if git push -u origin main; then
    echo ""
    echo "=========================================================="
    echo "Successfully pushed to GitHub!"
    echo "Repository: https://github.com/Maaz2007/antigravity-tts"
    echo "=========================================================="
else
    echo ""
    echo "If the repository does not exist on your GitHub yet:"
    echo "1. Go to: https://github.com/new"
    echo "2. Set Repository name to: antigravity-tts"
    echo "3. Choose Public (so you and friends can download it)"
    echo "4. Do NOT initialize with README (we already have a complete one)"
    echo "5. Click 'Create repository'"
    echo "6. Run this script again: ./push-to-github.sh"
fi
