#!/usr/bin/env bash
# ==============================================================================
# Register Antigravity TTS GNOME Global Shortcuts:
# 1. Super + R       : Play / Pause / Resume
# 2. Super + Shift + R: Complete Stop & Reset
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/antigravity-tts.sh"

PATH_PLAY="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts/"
SCHEMA_PLAY="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_PLAY"

PATH_STOP="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts-stop/"
SCHEMA_STOP="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_STOP"

MEDIA_KEYS_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"

echo "Configuring GNOME Custom Shortcuts for Antigravity TTS..."

# 1. Ensure target script is executable
chmod +x "$TARGET_SCRIPT"

# 2. Shortcut 1: Super + R (Play / Pause / Resume)
gsettings set "$SCHEMA_PLAY" name "Antigravity TTS (Play/Pause/Resume)"
gsettings set "$SCHEMA_PLAY" command "$TARGET_SCRIPT --toggle"
gsettings set "$SCHEMA_PLAY" binding "<Super>r"

# 3. Shortcut 2: Super + Shift + R (Complete Stop)
gsettings set "$SCHEMA_STOP" name "Antigravity TTS (Complete Stop)"
gsettings set "$SCHEMA_STOP" command "$TARGET_SCRIPT --stop"
gsettings set "$SCHEMA_STOP" binding "<Super><Shift>r"

# 4. Update the active custom-keybindings list
python3 -c "
import ast, subprocess

cmd = ['gsettings', 'get', '$MEDIA_KEYS_SCHEMA', 'custom-keybindings']
out = subprocess.check_output(cmd).decode().strip()

try:
    bindings = ast.literal_eval(out) if out not in ['@as []', '[]'] else []
except Exception:
    bindings = []

p1 = '$PATH_PLAY'
p2 = '$PATH_STOP'

if p1 not in bindings:
    bindings.append(p1)
if p2 not in bindings:
    bindings.append(p2)

formatted = '[' + ', '.join([f\"'{b}'\" for b in bindings]) + ']'
subprocess.run(['gsettings', 'set', '$MEDIA_KEYS_SCHEMA', 'custom-keybindings', formatted], check=True)
"

# 5. Ensure convenient symlink in ~/.local/bin
mkdir -p "$HOME/.local/bin"
ln -sf "$TARGET_SCRIPT" "$HOME/.local/bin/antigravity-tts"

echo "Shortcuts successfully configured!"
echo "  Super + R       -> Play / Pause / Resume ($TARGET_SCRIPT --toggle)"
echo "  Super + Shift + R -> Complete Stop ($TARGET_SCRIPT --stop)"
echo "Active Custom Keybindings: $(gsettings get "$MEDIA_KEYS_SCHEMA" custom-keybindings)"
