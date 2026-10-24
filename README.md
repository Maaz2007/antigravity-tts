# Antigravity Text-to-Speech (TTS) for Ubuntu

A fast, studio-quality, 100% offline Neural Text-to-Speech (TTS) utility tailored for Google Antigravity IDE and GNOME on Ubuntu (Wayland & X11).

Powered by the **Piper Neural VITS Synthesis Engine**, **PipeWire Real-Time Streaming**, and **Bilingual Hinglish Preprocessing**.

---

## ⚡ 1-Step Installation (For Any Laptop or Friend)

To install this tool on **any** Ubuntu/Debian laptop in a single command, open a terminal and run:

```bash
git clone https://github.com/Maaz2007/antigravity-tts.git && cd antigravity-tts && ./install.sh
```

**That's it!** The installer will:
1. Detect your system architecture (`x86_64` or `arm64`).
2. Download the lightweight standalone Piper neural speech engine.
3. Download the natural voice models:
   - `lessac` (Studio US voice)
   - `amy` (Warm conversational voice)
   - `rohan` (`hi_IN-rohan-medium`: Native Indian Bilingual & Hinglish voice)
4. Automatically register your GNOME desktop shortcuts:
   - **`Super + R`**: Play / Pause / Resume
   - **`Super + Shift + R`**: Complete Stop
5. Validate audio routing and run the test suite to verify everything works immediately.

---

## 🇮🇳 Native Hinglish & Code Pronunciation Support

Reading Hinglish (Hindi typed in English letters like *"bhai yeh function run nahi ho raha hai"*) typically causes English speech engines to mispronounce words.

Our preprocessor (`preprocess.py`) automatically fixes this:
- **Automatic Phonetic Transliteration**:
  - Words like `bhai`, `kya`, `nahi`, `karo`, `yeh`, `achha`, `theek`, `hota`, `raha` are converted to native phonetic representations.
  - English acoustic models speak them with native Hindi phonology instead of awkward English phonetic guesses.
- **Bilingual Hybrid Intelligence**:
  - Technical English terms (`function`, `database`, `user_id`, `return`, `console`, `error`) remain in clean English.
  - Operators (`!=`, `==`, `>=`, `<=`, `&&`, `||`, `=>`) are translated into natural phrases (*"not equal to"*, *"equals"*, *"arrow"*).
- **Dedicated Indian Bilingual Model**:
  - Includes **`hi_IN-rohan-medium`** for authentic Indian English and Hinglish cadence.

---

## ⌨️ Keyboard Shortcuts & Controls

| Shortcut | Action | Behavior |
|---|---|---|
| **`Super + R`** | **Play / Pause / Resume** | - **Instant Start (<250ms)**: Real-time asynchronous streaming begins speaking immediately.<br>- **Second Press**: **Pauses immediately** at the exact millisecond.<br>- **Third Press**: **Resumes playback** right from where you paused.<br>*(If you select different code while paused, it starts reading the new code from the beginning).* |
| **`Super + Shift + R`** | **Complete Stop & Reset** | - **Instant Silence**: Immediately cuts all audio output.<br>- Kills any active speech processes.<br>- Clears queue and resets player state to idle. |

---

## 🛠️ Usage Guide

### In Google Antigravity IDE
1. **Highlight** any English, Code, or Hinglish text in Antigravity.
2. **Press `Super + R`** to hear it spoken aloud.
3. **Press `Super + R`** again to **pause**.
4. **Press `Super + R`** again to **resume**.
5. **Press `Super + Shift + R`** at any time to **completely stop** and reset.

---

## ⚙️ Voice Customization

Edit `/home/maaz/antigravity-tts/config.env` to change your voice preferences:

```bash
# Voice Model:
# "en_US-lessac-medium"  - Articulate, crisp, studio clarity (Default)
# "hi_IN-rohan-medium"   - Native Indian Bilingual (Best for Hinglish & Indian English)
# "en_US-amy-medium"     - Warm, conversational tone
PIPER_VOICE="en_US-lessac-medium"

# Speech speed scale:
# 1.0  = Normal conversational pace
# 0.95 = Snappy, slightly faster (recommended)
# 1.10 = Slower, deliberate pacing
PIPER_SPEED="0.95"

# Smart code and Hinglish pronunciation preprocessor
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
