# Antigravity Text-to-Speech (TTS) for Ubuntu

A fast, studio-quality, 100% human-grade Text-to-Speech (TTS) utility tailored for Google Antigravity IDE and GNOME on Ubuntu (Wayland & X11).

Equipped with **Ultra-Realistic Studio Neural Voices** (Edge Neural Engine), **100% Offline Local Neural Backup** (Piper VITS), **Exact-Millisecond Resume**, **Dynamic Speed Adjustment**, and an **Intelligent Explanatory Pause Structurer**.

---

## ⚡ 1-Step Installation (For Any Laptop or Friend)

To install this tool on **any** Ubuntu/Debian laptop in a single command, open a terminal and run:

```bash
git clone https://github.com/Maaz2007/antigravity-tts.git && cd antigravity-tts && ./install.sh
```

**That's it!** The installer automatically sets up:
1. Studio-grade neural speech environment with Edge-TTS (`hi-IN-MadhurNeural`).
2. Standalone offline Piper neural engine & voice models (`hi_IN-pratham-medium`, `en_US-lessac-medium`).
3. Automated GNOME desktop shortcuts:
   - **`Super + R`**: Play / Pause / Resume
   - **`Super + Alt + R`**: Adjust Speed / Faster Speech (1.0x $\rightarrow$ 1.25x $\rightarrow$ 1.5x $\rightarrow$ 1.75x)
   - **`Super + Shift + R`**: Complete Stop & Reset
4. Audio pipeline validation & test suite verification.

---

## ⌨️ Keyboard Shortcuts & Controls

| Shortcut | Action | Behavior |
|---|---|---|
| **`Super + R`** | **Play / Pause / Resume** | - **Instant Start**: Begins speaking highlighted text in human studio voice.<br>- **Second Press**: **Pauses immediately** at the exact millisecond.<br>- **Third Press**: **Resumes playback** right from where you paused without restarting from the beginning.<br>*(If you highlight genuinely new text while paused, it starts reading the new text).* |
| **`Super + Alt + R`** | **Speed Adjustment (Faster / Normal)** | - **Cycle Speed On-The-Fly**: Dynamically cycles speech speed: **`1.0x (Normal)`** $\rightarrow$ **`1.25x (Fast)`** $\rightarrow$ **`1.5x (Super Fast)`** $\rightarrow$ **`1.75x (Turbo)`** $\rightarrow$ **`1.0x`**.<br>- Displays instant desktop notification showing the active speed.<br>- If audio is currently playing, dynamically updates speech pace immediately. |
| **`Super + Shift + R`** | **Complete Stop & Reset** | - **Instant Silence**: Immediately cuts all audio output.<br>- Kills any active speech processes.<br>- Clears playback queue and resets state to idle. |

---

## 🎙️ Natural Human Hindi, Hinglish & Explanation Prosody

Reading explanations, code, or mixed Hinglish (*"bhai ye function kaam nhi kr rha hai dekhna padega"*) often sounds rushed or robotic on standard synthesizers.

Antigravity TTS provides **natural, expressive, human-like speech**:

1. **Explanatory Pause Structuring & Breath Moments (`preprocess.py`)**:
   - **Header & Title Pauses**: Section headings (`# Title`) automatically get colon pauses so the voice pauses before starting the body text.
   - **List & Step-by-Step Breath Moments**: Bullet items (`-`, `*`) and numbered steps (`1.`, `2.`) are structured so the voice takes a natural breath between items instead of rushing through as a giant run-on sentence.
   - **Conversational Transition Clauses**: Naturally pauses around phrases like `जैसे कि` (*"for example"*), `मतलब` (*"meaning"*), `देखिए` (*"look"*), `लेकिन` (*"however"*), and `सबसे पहले` (*"first of all"*).
2. **Accurate Hinglish Transliteration**:
   - Colloquial chat forms (`nhi` $\rightarrow$ `नहीं`, `rha` $\rightarrow$ `रहा`, `kr` $\rightarrow$ `कर`, `padega` $\rightarrow$ `पड़ेगा`, `samjh` $\rightarrow$ `समझ`, `bhot` $\rightarrow$ `बहुत`) are transliterated to native phonetics.
   - Zero English collisions: English words like `the`, `user`, `return`, `function`, `price` remain in crystal-clear English.
3. **Studio Human Voice + Offline Fallback**:
   - Primary: **`hi-IN-MadhurNeural`** (warm, friendly male voice with authentic Hindi and English diction).
   - Offline Backup: Automatically falls back to local **Piper Neural TTS** with `hi_IN-pratham-medium` and `hi_IN-rohan-medium` with expressive pitch dynamics.

---

## 🛠️ Usage Guide

### In Google Antigravity IDE
1. **Highlight** any English, Code, Hindi, or Hinglish text in Antigravity.
2. **Press `Super + R`** (Windows key + R) to start speaking.
3. **Press `Super + R`** again to **pause**.
4. **Press `Super + R`** again to **resume** right from where you stopped.
5. **Press `Super + Alt + R`** to make it speak faster or slower.
6. **Press `Super + Shift + R`** at any time to **completely stop** and reset.

---

## ⚙️ Voice & Speed Customization

Edit `/home/maaz/antigravity-tts/config.env` to configure your preferences:

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
# - "hi_IN-rohan-medium"   : Expressive Indian Bilingual voice
PIPER_VOICE="hi_IN-pratham-medium"
```

---

## 🧪 Diagnostics & Verification

- **Check Current Status & Speed**:
  ```bash
  antigravity-tts --status
  ```
- **Inspect Live Logs**:
  ```bash
  cat /run/user/$(id -u)/antigravity-tts/tts.log
  ```
- **Run Full Automated Test Suite**:
  ```bash
  ~/antigravity-tts/test-tts.sh
  ```

---

## 🗑️ Uninstallation

To completely remove the shortcuts, scripts, and downloaded models:
```bash
~/antigravity-tts/uninstall.sh
```
