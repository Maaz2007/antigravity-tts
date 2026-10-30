#!/usr/bin/env bash
# ==============================================================================
# Antigravity Text-to-Speech (TTS) Engine
# Ultra-Realistic Human Speech for Hindi, Hinglish, and English
# Studio-Grade Edge Neural Voice + Offline Piper Neural Engine Fallback
# Includes Dynamic Speed Adjustment (<Super><Alt>r) & Complete Stop (<Super><Shift>r)
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

# Prioritize project bundled virtualenv and binaries
export PATH="$SCRIPT_DIR/venv/bin:$SCRIPT_DIR/bin:$SCRIPT_DIR/bin/piper:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Load configuration with fallback defaults
CONFIG_FILE="$SCRIPT_DIR/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

TTS_ENGINE="${TTS_ENGINE:-edge}"
EDGE_VOICE="${EDGE_VOICE:-hi-IN-MadhurNeural}"
EDGE_RATE="${EDGE_RATE:-+0%}"

PIPER_VOICE="${PIPER_VOICE:-hi_IN-pratham-medium}"
PIPER_SPEED="${PIPER_SPEED:-0.95}"
PIPER_SENTENCE_PAUSE="${PIPER_SENTENCE_PAUSE:-0.35}"
PIPER_NOISE_SCALE="${PIPER_NOISE_SCALE:-0.75}"
PIPER_NOISE_W="${PIPER_NOISE_W:-0.85}"

ENABLE_PREPROCESSOR="${ENABLE_PREPROCESSOR:-true}"
FALLBACK_TO_PIPER="${FALLBACK_TO_PIPER:-true}"

ESPEAK_VOICE="${ESPEAK_VOICE:-en-us}"
ESPEAK_SPEED="${ESPEAK_SPEED:-175}"
ESPEAK_PITCH="${ESPEAK_PITCH:-50}"
ESPEAK_AMPLITUDE="${ESPEAK_AMPLITUDE:-100}"

MAX_CHARS="${MAX_CHARS:-25000}"
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-true}"
SELECTION_MODE="${SELECTION_MODE:-primary}"

# State management
STATE_DIR="${XDG_RUNTIME_DIR}/antigravity-tts"
mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR"
PID_FILE="$STATE_DIR/player.pid"
SYNTH_PID_FILE="$STATE_DIR/synth.pid"
FIFO_FILE="$STATE_DIR/audio.pipe"
TEXT_FILE="$STATE_DIR/current_text.txt"
SPEED_FILE="$STATE_DIR/speed.conf"
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
        notify-send -u "$urgency" -a "Antigravity TTS" "$title" "$message" >/dev/null 2>&1 &
    fi
}

get_active_speed_rate() {
    if [[ -f "$SPEED_FILE" ]]; then
        cat "$SPEED_FILE" 2>/dev/null || echo "$EDGE_RATE"
    else
        echo "$EDGE_RATE"
    fi
}

get_piper_speed_for_rate() {
    local rate="$1"
    case "$rate" in
        "+25%") echo "0.80" ;;
        "+50%") echo "0.67" ;;
        "+75%") echo "0.57" ;;
        *)      echo "0.95" ;;
    esac
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
        rm -f "$PID_FILE" "$SYNTH_PID_FILE" "$FIFO_FILE" 2>/dev/null || true
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

# Complete Stop: Halts all audio immediately, clears queue, and resets state to idle
stop_speech() {
    local pid=""
    if [[ -f "$PID_FILE" ]]; then
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    fi
    local synth_pid=""
    if [[ -f "$SYNTH_PID_FILE" ]]; then
        synth_pid="$(cat "$SYNTH_PID_FILE" 2>/dev/null || true)"
    fi

    log "Stopping speech completely (Player PID: ${pid:-none}, Synth PID: ${synth_pid:-none})..."

    # Immediately terminate active processes
    if [[ -n "$pid" ]]; then
        kill -KILL "$pid" 2>/dev/null || true
    fi
    if [[ -n "$synth_pid" ]]; then
        kill -KILL "$synth_pid" 2>/dev/null || true
    fi

    # Terminate any remaining player or synth processes
    pkill -u "$USER" -x pw-play 2>/dev/null || true
    pkill -u "$USER" -x aplay 2>/dev/null || true
    pkill -u "$USER" -x piper 2>/dev/null || true
    pkill -u "$USER" -f "edge-tts" 2>/dev/null || true
    pkill -u "$USER" -x espeak-ng 2>/dev/null || true

    # Clean up state and FIFO pipe
    rm -f "$PID_FILE" "$SYNTH_PID_FILE" "$FIFO_FILE" "$TEXT_FILE" 2>/dev/null || true

    log "Speech stopped completely."
    notify "Antigravity TTS" "Speech stopped completely." "low"
    return 0
}

# Internal stop without removing TEXT_FILE (used when restarting playback)
stop_speech_internal() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]]; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    fi
    if [[ -f "$SYNTH_PID_FILE" ]]; then
        local synth_pid
        synth_pid="$(cat "$SYNTH_PID_FILE" 2>/dev/null || true)"
        if [[ -n "$synth_pid" ]]; then
            kill -KILL "$synth_pid" 2>/dev/null || true
        fi
    fi
    pkill -u "$USER" -x pw-play 2>/dev/null || true
    pkill -u "$USER" -x aplay 2>/dev/null || true
    pkill -u "$USER" -x piper 2>/dev/null || true
    pkill -u "$USER" -f "edge-tts" 2>/dev/null || true
    rm -f "$PID_FILE" "$SYNTH_PID_FILE" "$FIFO_FILE" 2>/dev/null || true
}

# Pause currently playing audio immediately
pause_speech() {
    local paused_any=0
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -STOP "$pid" 2>/dev/null || true
            paused_any=1
        fi
    fi
    if [[ -f "$SYNTH_PID_FILE" ]]; then
        local synth_pid
        synth_pid="$(cat "$SYNTH_PID_FILE" 2>/dev/null || true)"
        if [[ -n "$synth_pid" ]] && kill -0 "$synth_pid" 2>/dev/null; then
            kill -STOP "$synth_pid" 2>/dev/null || true
        fi
    fi

    if [[ $paused_any -eq 1 ]]; then
        log "Speech paused."
        notify "Antigravity TTS" "Paused. Press Super+R to resume." "low"
    fi
    return 0
}

# Resume paused audio from the exact stopped point
resume_speech() {
    local resumed_any=0
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -CONT "$pid" 2>/dev/null || true
            resumed_any=1
        fi
    fi
    if [[ -f "$SYNTH_PID_FILE" ]]; then
        local synth_pid
        synth_pid="$(cat "$SYNTH_PID_FILE" 2>/dev/null || true)"
        if [[ -n "$synth_pid" ]] && kill -0 "$synth_pid" 2>/dev/null; then
            kill -CONT "$synth_pid" 2>/dev/null || true
        fi
    fi

    if [[ $resumed_any -eq 1 ]]; then
        log "Speech resumed."
        notify "Antigravity TTS" "Resumed speech." "low"
        return 0
    fi
    return 1
}

# Cycle speech speed (Normal 1.0x -> Fast 1.25x -> Super Fast 1.5x -> Turbo 1.75x -> Normal 1.0x)
cycle_speed() {
    local current
    current="$(get_active_speed_rate)"
    local next_rate="+0%"
    local label="1.0x (Normal)"

    case "$current" in
        "+0%"|"1.0x"|"")
            next_rate="+25%"
            label="1.25x (Fast)"
            ;;
        "+25%"|"1.25x")
            next_rate="+50%"
            label="1.5x (Super Fast)"
            ;;
        "+50%"|"1.5x")
            next_rate="+75%"
            label="1.75x (Turbo)"
            ;;
        *)
            next_rate="+0%"
            label="1.0x (Normal)"
            ;;
    esac

    echo "$next_rate" > "$SPEED_FILE"
    log "Speed adjusted to $label ($next_rate)"
    notify "Antigravity TTS Speed" "Speed: $label" "low"

    # If speech is active, restart seamlessly with the new speed so user hears the tempo change immediately
    local state
    state="$(get_player_state)"
    if [[ "$state" == "playing" ]] && [[ -f "$TEXT_FILE" ]]; then
        local current_text
        current_text="$(cat "$TEXT_FILE" 2>/dev/null || true)"
        if [[ -n "$current_text" ]]; then
            speak_text "$current_text"
        fi
    fi
}

find_edge_tts() {
    if [[ -x "$SCRIPT_DIR/venv/bin/edge-tts" ]]; then
        echo "$SCRIPT_DIR/venv/bin/edge-tts"
    elif command -v edge-tts >/dev/null 2>&1; then
        command -v edge-tts
    elif [[ -x "$HOME/.local/bin/uvx" ]]; then
        echo "$HOME/.local/bin/uvx edge-tts"
    else
        echo ""
    fi
}

is_online_for_edge() {
    python3 -c "import socket; socket.create_connection(('speech.platform.bing.com', 443), timeout=0.8)" 2>/dev/null
}

# Select best Piper voice based on language content
select_piper_voice() {
    local text="$1"
    # Check if text contains Devanagari characters
    local has_hindi=0
    if python3 -c "import sys, re; sys.exit(0 if re.search(r'[\u0900-\u097F]', sys.argv[1]) else 1)" "$text" 2>/dev/null; then
        has_hindi=1
    fi

    if [[ $has_hindi -eq 1 ]]; then
        if [[ -f "$SCRIPT_DIR/voices/hi_IN-rohan-medium.onnx" ]]; then
            echo "$SCRIPT_DIR/voices/hi_IN-rohan-medium.onnx"
            return 0
        elif [[ -f "$SCRIPT_DIR/voices/hi_IN-pratham-medium.onnx" ]]; then
            echo "$SCRIPT_DIR/voices/hi_IN-pratham-medium.onnx"
            return 0
        fi
    fi

    # Fall back to configured Piper voice
    local configured="$SCRIPT_DIR/voices/${PIPER_VOICE}.onnx"
    if [[ -f "$configured" ]]; then
        echo "$configured"
    else
        find "$SCRIPT_DIR/voices" -name "*.onnx" | head -n 1
    fi
}

# Start speech with human-like voice
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
        notify "Antigravity TTS" "Selection is large; reading first $MAX_CHARS characters." "low"
    fi

    # Clean existing playback state first
    stop_speech_internal

    # Save original text for change detection and resume continuity
    printf '%s' "$text" > "$TEXT_FILE"

    # Active speed rate
    local active_rate
    active_rate="$(get_active_speed_rate)"
    local active_piper_speed
    active_piper_speed="$(get_piper_speed_for_rate "$active_rate")"

    # Fast preprocessor pass for pause structuring and Hinglish transliteration
    local processed_text="$text"
    if [[ "$ENABLE_PREPROCESSOR" == "true" ]] && [[ -f "$SCRIPT_DIR/preprocess.py" ]] && command -v python3 >/dev/null 2>&1; then
        processed_text="$(python3 "$SCRIPT_DIR/preprocess.py" <<< "$text" 2>/dev/null || echo "$text")"
    fi

    local preview="${text:0:50}"
    preview="$(echo "$preview" | tr '\n' ' ')"

    # Create FIFO for audio streaming
    rm -f "$FIFO_FILE"
    mkfifo "$FIFO_FILE"

    # Method 1: Edge-TTS Engine (Ultra-Human Studio Neural Speech)
    local edge_cmd
    edge_cmd="$(find_edge_tts)"
    if [[ "$TTS_ENGINE" == "edge" ]] && [[ -n "$edge_cmd" ]] && is_online_for_edge; then
        log "Starting Edge-TTS neural speech (${#processed_text} chars, voice: $EDGE_VOICE, rate: $active_rate)..."

        # Launch audio player on FIFO
        if command -v pw-play >/dev/null 2>&1; then
            pw-play "$FIFO_FILE" >> "$LOG_FILE" 2>&1 &
            local player_pid=$!
        else
            aplay "$FIFO_FILE" >> "$LOG_FILE" 2>&1 &
            local player_pid=$!
        fi
        echo "$player_pid" > "$PID_FILE"

        # Launch edge-tts writing to FIFO in background
        (
            $edge_cmd --voice "$EDGE_VOICE" --rate "$active_rate" --text "$processed_text" --write-media "$FIFO_FILE" >> "$LOG_FILE" 2>&1
            rm -f "$SYNTH_PID_FILE" 2>/dev/null || true
        ) &
        local synth_pid=$!
        echo "$synth_pid" > "$SYNTH_PID_FILE"

        notify "Antigravity TTS" "Speaking: \"${preview}...\"" "low"
        log "Edge-TTS streaming started (Player PID: $player_pid, Synth PID: $synth_pid)"
        return 0
    fi

    # Method 2: Piper Neural Engine (100% Local Offline Fallback with Expressive Prosody)
    if [[ -x "$SCRIPT_DIR/bin/piper/piper" ]]; then
        local model_path
        model_path="$(select_piper_voice "$processed_text")"

        if [[ -n "$model_path" ]] && [[ -f "$model_path" ]]; then
            log "Starting Piper neural speech (${#processed_text} chars, model: $(basename "$model_path"), speed: $active_piper_speed)..."

            if command -v pw-play >/dev/null 2>&1; then
                pw-play --rate 22050 --channels 1 --format s16 --raw "$FIFO_FILE" >> "$LOG_FILE" 2>&1 &
                local player_pid=$!
            else
                aplay -r 22050 -f S16_LE -t raw "$FIFO_FILE" >> "$LOG_FILE" 2>&1 &
                local player_pid=$!
            fi
            echo "$player_pid" > "$PID_FILE"

            (
                "$SCRIPT_DIR/bin/piper/piper" \
                    --model "$model_path" \
                    --length-scale "$active_piper_speed" \
                    --sentence-silence "$PIPER_SENTENCE_PAUSE" \
                    --noise-scale "$PIPER_NOISE_SCALE" \
                    --noise-w "$PIPER_NOISE_W" \
                    --output-raw <<< "$processed_text" > "$FIFO_FILE" 2>>"$LOG_FILE"
                rm -f "$SYNTH_PID_FILE" 2>/dev/null || true
            ) &
            local piper_pid=$!
            echo "$piper_pid" > "$SYNTH_PID_FILE"

            notify "Antigravity TTS" "Speaking: \"${preview}...\"" "low"
            log "Piper streaming started (Player PID: $player_pid, Piper PID: $piper_pid)"
            return 0
        fi
    fi

    # Method 3: Fallback to eSpeak NG
    local espeak_bin=""
    if [[ -x "$SCRIPT_DIR/bin/espeak-ng" ]]; then
        espeak_bin="$SCRIPT_DIR/bin/espeak-ng"
    elif command -v espeak-ng >/dev/null 2>&1; then
        espeak_bin="$(command -v espeak-ng)"
    fi

    if [[ -n "$espeak_bin" ]]; then
        log "Starting eSpeak fallback speech..."
        (
            exec "$espeak_bin" -v "$ESPEAK_VOICE" -s "$ESPEAK_SPEED" -p "$ESPEAK_PITCH" -a "$ESPEAK_AMPLITUDE" <<< "$processed_text" >> "$LOG_FILE" 2>&1
        ) &
        local player_pid=$!
        echo "$player_pid" > "$PID_FILE"
        notify "Antigravity TTS" "Speaking: \"${preview}...\"" "low"
        return 0
    fi

    log "Error: No viable speech engine found."
    notify "Antigravity TTS" "No speech engine available." "critical"
    return 1
}

# Toggle behavior:
# - If playing: Pause!
# - If paused: Resume (or start new if new text selection detected)!
# - If idle: Start speaking!
toggle_speech() {
    local state
    state="$(get_player_state)"

    if [[ "$state" == "playing" ]]; then
        pause_speech
        return 0
    elif [[ "$state" == "paused" ]]; then
        local current_sel
        current_sel="$(get_text_selection)"
        local old_sel=""
        if [[ -f "$TEXT_FILE" ]]; then
            old_sel="$(cat "$TEXT_FILE" 2>/dev/null || true)"
        fi

        local trimmed_curr
        trimmed_curr="$(echo -n "$current_sel" | tr -d '[:space:]')"
        local trimmed_old
        trimmed_old="$(echo -n "$old_sel" | tr -d '[:space:]')"

        if [[ -n "$trimmed_curr" ]] && [[ "$trimmed_curr" != "$trimmed_old" ]]; then
            log "New selection detected while paused. Restarting with new text..."
            speak_text "$current_sel"
        else
            resume_speech
        fi
        return 0
    else
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
    local active_voice="$EDGE_VOICE"
    if [[ "$TTS_ENGINE" == "piper" ]]; then
        active_voice="$PIPER_VOICE"
    fi
    local speed_rate
    speed_rate="$(get_active_speed_rate)"
    echo "Status: $state (PID: ${pid:-none}, Engine: $TTS_ENGINE, Voice: $active_voice, Speed: $speed_rate)"
}

show_help() {
    cat << EOF
Antigravity Text-to-Speech (TTS)
Usage: $(basename "$0") [OPTIONS]

Options:
  --toggle, -t      Toggle speech:
                      - If playing -> PAUSE immediately.
                      - If paused  -> RESUME from where it stopped.
                      - If idle    -> SPEAK selected text instantly. [DEFAULT]
  --cycle-speed     Cycle speech tempo / speed:
                      1.0x (Normal) -> 1.25x (Fast) -> 1.5x (Super Fast) -> 1.75x (Turbo) -> 1.0x
  --stop, -x        COMPLETE STOP: Immediately halts all audio, resets state, and clears queue.
  --pause           Pause active playback immediately.
  --resume          Resume paused playback from where it stopped.
  --speak, -s       Start speaking selected text (halts existing speech first).
  --status          Show whether speech is currently playing, paused, or idle.
  --text "TEXT"     Speak the specified text string directly.
  --help, -h        Display this help message.

Shortcuts Configured in GNOME:
  Super + R         Play / Pause / Resume
  Super + Alt + R   Cycle Speech Speed (Faster / Normal)
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
    --cycle-speed|--speed)
        cycle_speed
        ;;
    --speak|-s)
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
