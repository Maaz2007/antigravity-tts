#!/usr/bin/env bash
# ==============================================================================
# Antigravity Text-to-Speech (TTS) Engine
# High-Quality Neural TTS with Play / Pause / Resume & Complete Stop
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure core environment variables for Wayland / D-Bus / PipeWire
export USER="${USER:-$(id -un)}"
export HOME="${HOME:-$(getent passwd "$USER" | cut -d: -f6)}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

# Prioritize project bundled binaries
export PATH="$SCRIPT_DIR/bin:$SCRIPT_DIR/bin/piper:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Load configuration with fallback defaults
CONFIG_FILE="$SCRIPT_DIR/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

TTS_ENGINE="${TTS_ENGINE:-piper}"
PIPER_VOICE="${PIPER_VOICE:-en_US-lessac-medium}"
PIPER_SPEED="${PIPER_SPEED:-0.95}"
PIPER_SENTENCE_PAUSE="${PIPER_SENTENCE_PAUSE:-0.2}"
PIPER_NOISE_SCALE="${PIPER_NOISE_SCALE:-0.667}"
PIPER_NOISE_W="${PIPER_NOISE_W:-0.8}"
ENABLE_PREPROCESSOR="${ENABLE_PREPROCESSOR:-true}"

ESPEAK_VOICE="${ESPEAK_VOICE:-en-us}"
ESPEAK_SPEED="${ESPEAK_SPEED:-175}"
ESPEAK_PITCH="${ESPEAK_PITCH:-50}"
ESPEAK_AMPLITUDE="${ESPEAK_AMPLITUDE:-100}"

MAX_CHARS="${MAX_CHARS:-15000}"
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-true}"
SELECTION_MODE="${SELECTION_MODE:-primary}"

# State management
STATE_DIR="${XDG_RUNTIME_DIR}/antigravity-tts"
mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
PID_FILE="$STATE_DIR/player.pid"
AUDIO_FILE="$STATE_DIR/current_speech.wav"
TEXT_FILE="$STATE_DIR/current_text.txt"
LOG_FILE="$STATE_DIR/tts.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" >> "$LOG_FILE"
}

notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-low}"
    if [[ "$ENABLE_NOTIFICATIONS" == "true" ]] && command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -a "Antigravity TTS" "$title" "$message" 2>/dev/null || true
    fi
}

find_clipboard_reader() {
    local mode="$1"
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        local wl_paste_bin=""
        if [[ -x "$SCRIPT_DIR/bin/wl-paste" ]]; then
            wl_paste_bin="$SCRIPT_DIR/bin/wl-paste"
        elif command -v wl-paste >/dev/null 2>&1; then
            wl_paste_bin="$(command -v wl-paste)"
        fi

        if [[ -n "$wl_paste_bin" ]]; then
            if [[ "$mode" == "primary" ]]; then
                echo "$wl_paste_bin --primary --no-newline"
            else
                echo "$wl_paste_bin --no-newline"
            fi
            return 0
        fi
    fi

    # Fallback to X11 tools
    if command -v xclip >/dev/null 2>&1; then
        if [[ "$mode" == "primary" ]]; then
            echo "xclip -o -selection primary"
        else
            echo "xclip -o -selection clipboard"
        fi
        return 0
    elif command -v xsel >/dev/null 2>&1; then
        if [[ "$mode" == "primary" ]]; then
            echo "xsel -o -p"
        else
            echo "xsel -o -b"
        fi
        return 0
    fi

    echo ""
}

# Determine player state: "playing", "paused", or "idle"
get_player_state() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            local stat
            stat="$(ps -o stat= -p "$pid" 2>/dev/null || echo "")"
            if echo "$stat" | grep -q "T"; then
                echo "paused"
                return 0
            else
                echo "playing"
                return 0
            fi
        fi
        # Stale PID file
        rm -f "$PID_FILE" "$AUDIO_FILE" "$TEXT_FILE" 2>/dev/null || true
    fi
    echo "idle"
}

get_text_selection() {
    local reader_cmd
    reader_cmd="$(find_clipboard_reader "$SELECTION_MODE")"
    if [[ -z "$reader_cmd" ]]; then
        log "Error: No clipboard reader found for session."
        notify "Antigravity TTS" "Clipboard reader (wl-paste) not available." "critical"
        return 1
    fi

    local raw_text=""
    raw_text="$($reader_cmd 2>/dev/null || true)"
    echo "$raw_text"
}

# Complete Stop: Kills everything immediately and resets state to idle
stop_speech() {
    local state
    state="$(get_player_state)"
    local pid=""
    if [[ -f "$PID_FILE" ]]; then
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    fi

    log "Stopping speech completely (PID: ${pid:-none}, state: $state)..."

    # Immediately terminate active audio player
    if [[ -n "$pid" ]]; then
        kill -KILL "$pid" 2>/dev/null || true
    fi

    # Terminate any remaining synth or audio player processes
    pkill -u "$USER" -x pw-play 2>/dev/null || true
    pkill -u "$USER" -x aplay 2>/dev/null || true
    pkill -u "$USER" -x piper 2>/dev/null || true
    pkill -u "$USER" -x espeak-ng 2>/dev/null || true

    # Clean up state files
    rm -f "$PID_FILE" "$AUDIO_FILE" "$TEXT_FILE" 2>/dev/null || true

    log "Speech stopped completely."
    notify "Antigravity TTS" "Speech stopped completely." "low"
    return 0
}

# Pause currently playing audio immediately
pause_speech() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -STOP "$pid" 2>/dev/null || true
            log "Speech paused (PID: $pid)."
            notify "Antigravity TTS" "Paused. Press Super+R to resume." "low"
            return 0
        fi
    fi
    return 0
}

# Resume paused audio from the exact position
resume_speech() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -CONT "$pid" 2>/dev/null || true
            log "Speech resumed (PID: $pid)."
            notify "Antigravity TTS" "Resumed speech." "low"
            return 0
        fi
    fi
    return 1
}

# Start new speech
speak_text() {
    local text="$1"

    # Trim whitespace
    local trimmed
    trimmed="$(echo -n "$text" | tr -d '[:space:]')"
    if [[ -z "$trimmed" ]]; then
        log "No active text selection detected. Skipping speech."
        notify "Antigravity TTS" "No text selected in Antigravity." "low"
        return 0
    fi

    # Prevent runaway text length
    local char_count="${#text}"
    if [[ $char_count -gt $MAX_CHARS ]]; then
        log "Text length ($char_count chars) exceeds MAX_CHARS ($MAX_CHARS). Truncating."
        text="${text:0:$MAX_CHARS}"
        notify "Antigravity TTS" "Selection is long; reading first $MAX_CHARS characters." "low"
    fi

    # Save original text for change detection
    echo "$text" > "$TEXT_FILE"

    # Preprocess text for natural pronunciation
    local processed_text="$text"
    if [[ "$ENABLE_PREPROCESSOR" == "true" ]] && [[ -f "$SCRIPT_DIR/preprocess.py" ]] && command -v python3 >/dev/null 2>&1; then
        processed_text="$(python3 "$SCRIPT_DIR/preprocess.py" <<< "$text" 2>/dev/null || echo "$text")"
    fi

    local preview="${text:0:50}"
    preview="$(echo "$preview" | tr '\n' ' ')"

    # Synthesize with Piper Neural Engine
    if [[ "$TTS_ENGINE" == "piper" ]] && [[ -x "$SCRIPT_DIR/bin/piper/piper" ]]; then
        local model_path="$SCRIPT_DIR/voices/${PIPER_VOICE}.onnx"
        if [[ ! -f "$model_path" ]]; then
            model_path="$(find "$SCRIPT_DIR/voices" -name "*.onnx" | head -n 1)"
        fi

        if [[ -n "$model_path" ]] && [[ -f "$model_path" ]]; then
            log "Synthesizing neural audio (${#processed_text} chars, model: $(basename "$model_path"))..."
            
            # Generate WAV file
            "$SCRIPT_DIR/bin/piper/piper" \
                --model "$model_path" \
                --length-scale "$PIPER_SPEED" \
                --sentence-silence "$PIPER_SENTENCE_PAUSE" \
                --noise-scale "$PIPER_NOISE_SCALE" \
                --noise-w "$PIPER_NOISE_W" \
                --output-file "$AUDIO_FILE" <<< "$processed_text" 2>>"$LOG_FILE"

            # Launch player directly (so $! is the actual audio player PID)
            if command -v pw-play >/dev/null 2>&1; then
                pw-play "$AUDIO_FILE" >> "$LOG_FILE" 2>&1 &
                local player_pid=$!
            else
                aplay "$AUDIO_FILE" >> "$LOG_FILE" 2>&1 &
                local player_pid=$!
            fi

            echo "$player_pid" > "$PID_FILE"
            notify "Antigravity TTS" "Speaking: \"${preview}...\"" "low"
            log "Audio playback started with PID $player_pid"
            return 0
        fi
    fi

    # Fallback to eSpeak NG
    local espeak_bin=""
    if [[ -x "$SCRIPT_DIR/bin/espeak-ng" ]]; then
        espeak_bin="$SCRIPT_DIR/bin/espeak-ng"
    elif command -v espeak-ng >/dev/null 2>&1; then
        espeak_bin="$(command -v espeak-ng)"
    fi

    if [[ -n "$espeak_bin" ]]; then
        log "Starting eSpeak fallback speech..."
        "$espeak_bin" -w "$AUDIO_FILE" -v "$ESPEAK_VOICE" -s "$ESPEAK_SPEED" -p "$ESPEAK_PITCH" -a "$ESPEAK_AMPLITUDE" <<< "$processed_text" >> "$LOG_FILE" 2>&1
        if command -v pw-play >/dev/null 2>&1; then
            pw-play "$AUDIO_FILE" >> "$LOG_FILE" 2>&1 &
            local player_pid=$!
        else
            aplay "$AUDIO_FILE" >> "$LOG_FILE" 2>&1 &
            local player_pid=$!
        fi
        echo "$player_pid" > "$PID_FILE"
        notify "Antigravity TTS" "Speaking: \"${preview}...\"" "low"
        log "eSpeak playback started with PID $player_pid"
        return 0
    fi

    log "Error: No viable speech engine found."
    notify "Antigravity TTS" "No speech engine available." "critical"
    return 1
}

# Toggle behavior:
# - If playing: Pause!
# - If paused: Resume (or start new if new selection detected)!
# - If idle: Start speaking!
toggle_speech() {
    local state
    state="$(get_player_state)"

    if [[ "$state" == "playing" ]]; then
        pause_speech
        return 0
    elif [[ "$state" == "paused" ]]; then
        # Check if user highlighted a NEW different text
        local current_sel
        current_sel="$(get_text_selection)"
        local old_sel=""
        if [[ -f "$TEXT_FILE" ]]; then
            old_sel="$(cat "$TEXT_FILE" 2>/dev/null || true)"
        fi

        local trimmed_curr
        trimmed_curr="$(echo -n "$current_sel" | tr -d '[:space:]')"

        if [[ -n "$trimmed_curr" ]] && [[ "$current_sel" != "$old_sel" ]]; then
            log "New selection detected while paused. Restarting with new text..."
            stop_speech
            speak_text "$current_sel"
        else
            # Resume existing playback
            resume_speech
        fi
        return 0
    else
        # Idle: start fresh speech
        local text
        text="$(get_text_selection)"
        speak_text "$text"
        return 0
    fi
}

show_status() {
    local state
    state="$(get_player_state)"
    local pid=""
    if [[ -f "$PID_FILE" ]]; then
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    fi
    echo "Status: $state (PID: ${pid:-none}, Engine: $TTS_ENGINE, Voice: $PIPER_VOICE)"
}

show_help() {
    cat << EOF
Antigravity Text-to-Speech (TTS)
Usage: $(basename "$0") [OPTIONS]

Options:
  --toggle, -t      Toggle speech:
                      - If playing -> PAUSE immediately.
                      - If paused  -> RESUME from where it stopped.
                      - If idle    -> SPEAK selected text. [DEFAULT]
  --stop, -x        COMPLETE STOP: Immediately halts all audio, resets state, and clears queue.
  --pause           Pause active playback immediately.
  --resume          Resume paused playback from where it stopped.
  --speak, -s       Start speaking selected text (halts existing speech first).
  --status          Show whether speech is currently playing, paused, or idle.
  --text "TEXT"     Speak the specified text string directly.
  --help, -h        Display this help message.

Shortcuts Configured in GNOME:
  Super + R         Play / Pause / Resume
  Super + Shift + R Complete Stop (Instant silence & queue reset)
EOF
}

# Command dispatch
case "${1:-}" in
    --stop|-x)
        stop_speech
        ;;
    --pause)
        pause_speech
        ;;
    --resume)
        resume_speech
        ;;
    --speak|-s)
        stop_speech
        TEXT="$(get_text_selection)"
        speak_text "$TEXT"
        ;;
    --status)
        show_status
        ;;
    --text)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: --text requires an argument" >&2
            exit 1
        fi
        stop_speech
        speak_text "$*"
        ;;
    --help|-h)
        show_help
        ;;
    --toggle|-t|"")
        toggle_speech
        ;;
    *)
        echo "Unknown option: $1" >&2
        show_help >&2
        exit 1
        ;;
esac
