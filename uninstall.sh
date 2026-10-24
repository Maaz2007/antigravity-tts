#!/usr/bin/env bash
# ==============================================================================
# Uninstaller for Antigravity Text-to-Speech (TTS)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/antigravity-tts"

echo "=========================================================="
echo "      Antigravity Text-to-Speech (TTS) Uninstaller        "
echo "=========================================================="

# 1. Stop any currently active speech processes
echo "[1/4] Stopping active TTS processes..."
if [[ -x "$SCRIPT_DIR/antigravity-tts.sh" ]]; then
    "$SCRIPT_DIR/antigravity-tts.sh" --stop 2>/dev/null || true
fi
pkill -u "$USER" -x espeak-ng 2>/dev/null || true

# 2. Unregister GNOME keyboard shortcut
echo "[2/4] Removing GNOME keyboard shortcut..."
if [[ -x "$SCRIPT_DIR/unregister-shortcut.sh" ]]; then
    "$SCRIPT_DIR/unregister-shortcut.sh" || true
fi

# 3. Clean up runtime state and symlinks
echo "[3/4] Cleaning runtime state and command symlinks..."
rm -rf "$STATE_DIR" 2>/dev/null || true
rm -f "$HOME/.local/bin/antigravity-tts"

# 4. Remove installation directory
echo "[4/4] Removing installation directory ($SCRIPT_DIR)..."
cd "$HOME"
rm -rf "$SCRIPT_DIR"

echo "=========================================================="
echo "Antigravity TTS has been completely uninstalled."
echo "=========================================================="
