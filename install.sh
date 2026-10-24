#!/usr/bin/env bash
# ==============================================================================
# Antigravity Text-to-Speech (TTS) - One-Step Automated Installer
# Works on any Ubuntu / Debian Linux system with GNOME (Wayland or X11)
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}"
echo "=========================================================="
echo "    Antigravity Text-to-Speech (TTS) - One-Step Setup     "
echo "=========================================================="
echo -e "${NC}"

# 1. Detect Architecture
ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" ]] && [[ "$ARCH" != "aarch64" ]]; then
    echo -e "${RED}[ERROR] Unsupported CPU architecture: $ARCH. Only x86_64 and aarch64 are supported.${NC}"
    exit 1
fi

INSTALL_DIR="${TARGET_DIR:-$HOME/antigravity-tts}"
echo -e "${BLUE}[1/6] Preparing installation directory at: ${BOLD}$INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/voices"

# If running from a cloned git repo, copy template files over if different
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_SRC" != "$INSTALL_DIR" ]]; then
    echo -e "${BLUE}[2/6] Copying engine scripts and configurations...${NC}"
    cp -u "$SCRIPT_SRC"/antigravity-tts.sh "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/antigravity-tts.sh "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/preprocess.py "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/preprocess.py "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/config.env "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/config.env "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/register-shortcut.sh "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/register-shortcut.sh "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/unregister-shortcut.sh "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/unregister-shortcut.sh "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/test-tts.sh "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/test-tts.sh "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/uninstall.sh "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/uninstall.sh "$INSTALL_DIR/"
    cp -u "$SCRIPT_SRC"/README.md "$INSTALL_DIR/" 2>/dev/null || cp "$SCRIPT_SRC"/README.md "$INSTALL_DIR/"
fi

# 2. Setup Wayland Clipboard Utilities (wl-paste, wl-copy)
echo -e "${BLUE}[3/6] Setting up clipboard utilities (wl-clipboard)...${NC}"
if ! command -v wl-paste >/dev/null 2>&1 && [[ ! -x "$INSTALL_DIR/bin/wl-paste" ]]; then
    echo "Downloading wl-clipboard package..."
    TMP_WL="/tmp/wl_pkg_$$"
    mkdir -p "$TMP_WL"
    (
        cd "$TMP_WL"
        apt-get download wl-clipboard >/dev/null 2>&1 || true
        if ls wl-clipboard*.deb >/dev/null 2>&1; then
            dpkg -x wl-clipboard*.deb extracted/
            cp extracted/usr/bin/wl-paste "$INSTALL_DIR/bin/"
            cp extracted/usr/bin/wl-copy "$INSTALL_DIR/bin/"
        fi
    )
    rm -rf "$TMP_WL"
fi

# 3. Setup Piper Neural TTS Engine
echo -e "${BLUE}[4/6] Setting up Piper Neural TTS engine...${NC}"
if [[ ! -x "$INSTALL_DIR/bin/piper/piper" ]]; then
    PIPER_URL="https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_${ARCH}.tar.gz"
    echo "Downloading standalone Piper neural engine from $PIPER_URL..."
    TMP_PIPER="/tmp/piper_dl_$$"
    mkdir -p "$TMP_PIPER"
    curl -L -s "$PIPER_URL" -o "$TMP_PIPER/piper.tar.gz"
    tar -xzf "$TMP_PIPER/piper.tar.gz" -C "$TMP_PIPER"
    cp -r "$TMP_PIPER/piper" "$INSTALL_DIR/bin/piper"
    rm -rf "$TMP_PIPER"
    chmod +x "$INSTALL_DIR/bin/piper/piper"
fi
echo -e "${GREEN}✓ Piper neural engine is ready.${NC}"

# 4. Download Natural Neural Voice Models
echo -e "${BLUE}[5/6] Verifying neural voice models...${NC}"
HF_VOICES_URL="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US"

# Model 1: Lessac (Default studio-quality American voice)
if [[ ! -f "$INSTALL_DIR/voices/en_US-lessac-medium.onnx" ]]; then
    echo "Downloading en_US-lessac-medium voice model..."
    curl -L -s "$HF_VOICES_URL/lessac/medium/en_US-lessac-medium.onnx" -o "$INSTALL_DIR/voices/en_US-lessac-medium.onnx"
    curl -L -s "$HF_VOICES_URL/lessac/medium/en_US-lessac-medium.onnx.json" -o "$INSTALL_DIR/voices/en_US-lessac-medium.onnx.json"
fi

# Model 2: Amy (Warm expressive voice)
if [[ ! -f "$INSTALL_DIR/voices/en_US-amy-medium.onnx" ]]; then
    echo "Downloading en_US-amy-medium voice model..."
    curl -L -s "$HF_VOICES_URL/amy/medium/en_US-amy-medium.onnx" -o "$INSTALL_DIR/voices/en_US-amy-medium.onnx"
    curl -L -s "$HF_VOICES_URL/amy/medium/en_US-amy-medium.onnx.json" -o "$INSTALL_DIR/voices/en_US-amy-medium.onnx.json"
fi
echo -e "${GREEN}✓ Neural voice models ready.${NC}"

# 5. Set permissions and configure shortcuts
echo -e "${BLUE}[6/6] Configuring executable permissions and desktop shortcuts...${NC}"
chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR/preprocess.py" 2>/dev/null || true

# Register GNOME shortcuts
if [[ -x "$INSTALL_DIR/register-shortcut.sh" ]]; then
    "$INSTALL_DIR/register-shortcut.sh"
fi

# Run validation test
echo -e "\n${BLUE}Running system verification test...${NC}"
if [[ -x "$INSTALL_DIR/test-tts.sh" ]]; then
    "$INSTALL_DIR/test-tts.sh" || true
fi

echo -e "\n${GREEN}${BOLD}==========================================================${NC}"
echo -e "${GREEN}${BOLD}    Antigravity TTS Installed & Configured Successfully!  ${NC}"
echo -e "${GREEN}${BOLD}==========================================================${NC}"
echo -e "\n${BOLD}Quick Start Guide:${NC}"
echo -e "  1. Open Antigravity IDE and highlight any code or text."
echo -e "  2. Press ${YELLOW}${BOLD}Super + R${NC} to start speaking in natural human voice."
echo -e "  3. Press ${YELLOW}${BOLD}Super + R${NC} again to ${YELLOW}pause${NC}."
echo -e "  4. Press ${YELLOW}${BOLD}Super + R${NC} again to ${YELLOW}resume${NC} right from where you stopped."
echo -e "  5. Press ${YELLOW}${BOLD}Super + Shift + R${NC} to ${RED}completely stop${NC} and reset."
echo -e "\n${BOLD}Configuration File:${NC} $INSTALL_DIR/config.env"
echo -e "Enjoy listening to your code!"
