#!/usr/bin/env bash
# ==============================================================================
# Register Antigravity TTS GNOME Global Shortcuts:
# 1. Super + R        : Play / Pause / Resume
# 2. Super + Alt + R  : Cycle Speed (Normal -> Fast -> Super Fast -> Turbo)
# 3. Super + Shift + R: Complete Stop & Reset
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/antigravity-tts.sh"

PATH_PLAY="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts/"
SCHEMA_PLAY="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_PLAY"

PATH_SPEED="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts-speed/"
SCHEMA_SPEED="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_SPEED"

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

# 3. Shortcut 2: Super + Alt + R (Adjust Speed / Cycle Tempo)
gsettings set "$SCHEMA_SPEED" name "Antigravity TTS (Adjust Speed)"
gsettings set "$SCHEMA_SPEED" command "$TARGET_SCRIPT --cycle-speed"
gsettings set "$SCHEMA_SPEED" binding "<Super><Alt>r"

# 4. Shortcut 3: Super + Shift + R (Complete Stop & Reset)
gsettings set "$SCHEMA_STOP" name "Antigravity TTS (Complete Stop)"
gsettings set "$SCHEMA_STOP" command "$TARGET_SCRIPT --stop"
gsettings set "$SCHEMA_STOP" binding "<Super><Shift>r"

# 5. Update the active custom-keybindings list in dconf
python3 -c "
import ast, subprocess

cmd = ['gsettings', 'get', '$MEDIA_KEYS_SCHEMA', 'custom-keybindings']
out = subprocess.check_output(cmd).decode().strip()

try:
    bindings = ast.literal_eval(out) if out not in ['@as []', '[]'] else []
except Exception:
    bindings = []

p1 = '$PATH_PLAY'
p2 = '$PATH_SPEED'
p3 = '$PATH_STOP'

for p in [p1, p2, p3]:
    if p not in bindings:
        bindings.append(p)

formatted = '[' + ', '.join([f\"'{b}'\" for b in bindings]) + ']'
subprocess.run(['gsettings', 'set', '$MEDIA_KEYS_SCHEMA', 'custom-keybindings', formatted], check=True)
"

# 6. Ensure convenient symlink in ~/.local/bin
mkdir -p "$HOME/.local/bin"
ln -sf "$TARGET_SCRIPT" "$HOME/.local/bin/antigravity-tts"

echo "Shortcuts successfully configured!"
echo "  Super + R         -> Play / Pause / Resume ($TARGET_SCRIPT --toggle)"
echo "  Super + Alt + R   -> Cycle Speed / Faster Speech ($TARGET_SCRIPT --cycle-speed)"
echo "  Super + Shift + R -> Complete Stop & Reset ($TARGET_SCRIPT --stop)"
echo "Active Custom Keybindings: $(gsettings get "$MEDIA_KEYS_SCHEMA" custom-keybindings)"
