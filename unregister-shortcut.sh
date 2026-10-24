#!/usr/bin/env bash
# ==============================================================================
# Unregister Antigravity TTS GNOME Global Shortcuts
# ==============================================================================

set -euo pipefail

PATH_PLAY="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts/"
SCHEMA_PLAY="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_PLAY"

PATH_STOP="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts-stop/"
SCHEMA_STOP="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_STOP"

MEDIA_KEYS_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"

echo "Removing GNOME Custom Shortcuts for Antigravity TTS..."

# 1. Reset schemas
gsettings reset-recursively "$SCHEMA_PLAY" 2>/dev/null || true
gsettings reset-recursively "$SCHEMA_STOP" 2>/dev/null || true

# 2. Remove paths from list
python3 -c "
import ast, subprocess

cmd = ['gsettings', 'get', '$MEDIA_KEYS_SCHEMA', 'custom-keybindings']
out = subprocess.check_output(cmd).decode().strip()

try:
    bindings = ast.literal_eval(out) if out not in ['@as []', '[]'] else []
except Exception:
    bindings = []

remove_paths = {'$PATH_PLAY', '$PATH_STOP'}
filtered = [b for b in bindings if b not in remove_paths]

if filtered:
    formatted = '[' + ', '.join([f\"'{b}'\" for b in filtered]) + ']'
else:
    formatted = '@as []'

subprocess.run(['gsettings', 'set', '$MEDIA_KEYS_SCHEMA', 'custom-keybindings', formatted], check=True)
"

# 3. Remove symlink
rm -f "$HOME/.local/bin/antigravity-tts"

echo "Shortcuts successfully removed."
echo "Active Keybindings: $(gsettings get "$MEDIA_KEYS_SCHEMA" custom-keybindings)"
