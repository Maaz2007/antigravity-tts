# Antigravity Text-to-Speech (TTS) for Ubuntu

A fast, studio-quality, 100% offline Neural Text-to-Speech (TTS) utility tailored for Google Antigravity IDE and GNOME on Ubuntu (Wayland & X11).

Powered by the **Piper Neural VITS Synthesis Engine** and **PipeWire**.

---

## ⚡ 1-Step Installation (For Any Laptop or Friend)

To install this tool on **any** Ubuntu/Debian laptop in a single command, open a terminal and run:

```bash
git clone https://github.com/Maaz2007/antigravity-tts.git && cd antigravity-tts && ./install.sh
```

**That's it!** The installer will:
1. Detect your system architecture (`x86_64` or `arm64`).
2. Download the lightweight standalone Piper neural speech engine.
3. Download the high-quality natural voice models (`lessac` & `amy`).
4. Automatically register your GNOME desktop shortcuts:
   - **`Super + R`**: Play / Pause / Resume
   - **`Super + Shift + R`**: Complete Stop
5. Validate audio routing and run the test suite to verify everything works immediately.

---

## ⌨️ Keyboard Shortcuts & Controls

| Shortcut | Action | Behavior |
|---|---|---|
| **`Super + R`** | **Play / Pause / Resume** | - **First Press**: Speaks the selected text in Antigravity.<br>- **Second Press**: **Pauses immediately** at the exact millisecond.<br>- **Third Press**: **Resumes playback** right from where you paused.<br>*(If you select different code while paused, it starts reading the new code from the beginning).* |
| **`Super + Shift + R`** | **Complete Stop & Reset** | - **Instant Silence**: Immediately cuts all audio output.<br>- Kills any active speech processes.<br>- Clears queue and resets player state to idle. |

---

## 🎙️ Natural Voice & Code Preprocessing

- **Human Neural Voice**: Deep-learning ONNX acoustic models trained on voice actors with natural pitch inflection, vocal dynamics, and sentence breathing pauses.
- **Intelligent Code Pronunciation (`preprocess.py`)**:
  - Operators like `!=`, `==`, `>=`, `<=`, `&&`, `||`, `=>` are pronounced naturally (*"not equal to"*, *"equals"*, *"arrow"*).
  - Identifier underscores in `snake_case` (e.g. `calculate_total_tax`) are read as natural words (*"calculate total tax"*).
  - Markdown artifacts (`` ```python ``, `**bold**`, `###`) and lengthy URLs are cleaned automatically so symbols aren't read letter-by-letter.
- **100% Offline & Private**: Zero cloud dependencies; your proprietary code never leaves your computer.

---

## 🛠️ Usage Guide

### In Google Antigravity IDE
1. **Highlight** any text or code in Antigravity (editor, chat response, or terminal).
2. **Press `Super + R`** to hear it spoken aloud in a natural human voice.
3. **Press `Super + R`** again to **pause**.
4. **Press `Super + R`** again to **resume** right from where you paused.
5. **Press `Super + Shift + R`** at any time to **completely stop** and reset.

### From the Terminal
```bash
# Play / Pause / Resume toggle
antigravity-tts --toggle

# Complete Stop (instant silence)
antigravity-tts --stop

# Pause explicitly
antigravity-tts --pause

# Resume explicitly
antigravity-tts --resume

# Check status (playing, paused, idle)
antigravity-tts --status

# Speak custom text directly
antigravity-tts --text "Hello world"
```

---

## ⚙️ Voice Customization

Edit `/home/maaz/antigravity-tts/config.env` to adjust settings:

```bash
# Voice Model:
# "en_US-lessac-medium"  (Articulate, crisp, studio clarity - Default)
# "en_US-amy-medium"     (Warm, expressive, natural tone)
PIPER_VOICE="en_US-lessac-medium"

# Speech speed scale:
# 1.0  = Normal conversational pace
# 0.95 = Snappy, slightly faster (recommended)
# 1.10 = Slower, deliberate pacing
PIPER_SPEED="0.95"

# Natural sentence pause in seconds
PIPER_SENTENCE_PAUSE="0.2"

# Smart pronunciation preprocessor
ENABLE_PREPROCESSOR=true
```
*Changes take effect immediately on your next shortcut press—no reload needed!*

---

## 🧪 Diagnostics & Verification

- **Check Current Status**:
  ```bash
  antigravity-tts --status
  ```
- **Inspect Live Logs**:
  ```bash
  cat /run/user/$(id -u)/antigravity-tts/tts.log
  ```
- **Run Full Test Suite**:
  ```bash
  ~/antigravity-tts/test-tts.sh
  ```

---

## 🗑️ Uninstallation

To completely remove the shortcuts, scripts, and downloaded models:
```bash
~/antigravity-tts/uninstall.sh
```
