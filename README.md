# Antigravity Text-to-Speech (TTS) for Ubuntu

A fast, studio-quality, 100% human-grade Text-to-Speech (TTS) utility tailored for Google Antigravity IDE and GNOME on Ubuntu (Wayland & X11).

Equipped with **Ultra-Realistic Studio Neural Voices** (Edge Neural Engine) and **100% Offline Local Neural Backup** (Piper VITS), paired with **PipeWire Real-Time Streaming** and an **Intelligent Bilingual Hinglish Preprocessor**.

---

## ⚡ 1-Step Installation (For Any Laptop or Friend)

To install this tool on **any** Ubuntu/Debian laptop in a single command, open a terminal and run:

```bash
git clone https://github.com/Maaz2007/antigravity-tts.git && cd antigravity-tts && ./install.sh
```

**That's it!** The installer will:
1. Detect your system architecture (`x86_64` or `arm64`).
2. Set up the ultra-human Edge-TTS studio voice environment.
3. Download the standalone Piper offline neural engine and voice models (`hi_IN-pratham-medium`, `en_US-lessac-medium`).
4. Automatically register your GNOME desktop shortcuts:
   - **`Super + R`**: Play / Pause / Resume
   - **`Super + Shift + R`**: Complete Stop
5. Validate audio routing and run the test suite to verify everything works immediately.

---

## 🎙️ Natural Human Hindi & Hinglish Speech

Reading Hindi or Hinglish (Hindi typed in English letters like *"bhai ye function kaam nhi kr rha hai dekhna padega"*) often sounds awkward or robotic on ordinary synthesizers.

Antigravity TTS provides **flawless, human-grade pronunciation**:

1. **Ultra-Realistic Studio Neural Voices**:
   - **`hi-IN-MadhurNeural`** (Default): Male voice with warm, conversational human tone, natural pitch variations, and authentic Hindi diction.
   - **`hi-IN-SwaraNeural`**: Female voice with expressive, crystal-clear intonation.
2. **Comprehensive Hinglish Transliteration (`preprocess.py`)**:
   - Converts colloquial chat forms (`nhi`, `rha`, `kr`, `kro`, `padega`, `bhot`, `samjh`, `btao`, `thk`, `acha`) to native Devanagari phonetics.
   - Seamlessly preserves English technical keywords (`function`, `return`, `class`, `import`, `problem`, `user`, `calculate`).
   - Translates programming symbols (`!=`, `==`, `>=`, `<=`, `&&`, `||`, `=>`) into natural spoken words (*"not equal to"*, *"equals"*, *"arrow"*).
3. **100% Offline Neural Fallback**:
   - If internet is unavailable, it automatically switches to local **Piper Neural TTS** with `hi_IN-pratham-medium` for zero-downtime offline reading.

---

## ⌨️ Keyboard Shortcuts & Controls

| Shortcut | Action | Behavior |
|---|---|---|
| **`Super + R`** | **Play / Pause / Resume** | - **Instant Start**: Begins speaking highlighted text immediately.<br>- **Second Press**: **Pauses immediately** at the exact millisecond.<br>- **Third Press**: **Resumes playback** right from where you paused.<br>*(If you select different text while paused, it starts reading the new text from the beginning).* |
| **`Super + Shift + R`** | **Complete Stop & Reset** | - **Instant Silence**: Immediately cuts all audio output.<br>- Kills any active speech processes.<br>- Clears queue and resets player state to idle. |

---

## 🛠️ Usage Guide

### In Google Antigravity IDE
1. **Highlight** any English, Code, Hindi, or Hinglish text in Antigravity.
2. **Press `Super + R`** to hear it spoken aloud in human voice.
3. **Press `Super + R`** again to **pause**.
4. **Press `Super + R`** again to **resume**.
5. **Press `Super + Shift + R`** at any time to **completely stop** and reset.

---

## ⚙️ Voice Customization

Edit `/home/maaz/antigravity-tts/config.env` to configure your preferred voice:

```bash
# Engine: "edge" (Studio Human Neural) or "piper" (100% Local Offline)
TTS_ENGINE="edge"

# Studio Neural Voices:
# - "hi-IN-MadhurNeural" : Male Hindi & Hinglish - natural, warm human tone (Default)
# - "hi-IN-SwaraNeural"  : Female Hindi & Hinglish - expressive, clear human tone
# - "en-IN-PrabhatNeural": Male Indian English & Hinglish
# - "en-US-GuyNeural"    : Male American English
EDGE_VOICE="hi-IN-MadhurNeural"

# Offline Fallback Voice (Piper Engine):
# - "hi_IN-pratham-medium" : Clean Indian Hindi voice (Default offline)
# - "en_US-lessac-medium"  : US Studio clarity
PIPER_VOICE="hi_IN-pratham-medium"
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
