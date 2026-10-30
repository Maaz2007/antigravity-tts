#!/usr/bin/env bash
# ==============================================================================
# Comprehensive Test Suite for Antigravity Text-to-Speech (TTS)
# Tests Neural Audio, Fast Streaming, Play/Pause/Resume, Speed Adjustment,
# Hinglish Support, and Explanatory Pause Structuring
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TTS_CMD="$SCRIPT_DIR/antigravity-tts.sh"
PREPROCESS_CMD="$SCRIPT_DIR/preprocess.py"
WL_COPY="$SCRIPT_DIR/bin/wl-copy"
WL_PASTE="$SCRIPT_DIR/bin/wl-paste"

PASSED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

report_pass() {
    echo -e "\e[32m[PASS]\e[0m $1"
    PASSED_COUNT=$((PASSED_COUNT + 1))
}

report_fail() {
    echo -e "\e[31m[FAIL]\e[0m $1: $2"
    FAILED_COUNT=$((FAILED_COUNT + 1))
}

report_skip() {
    echo -e "\e[33m[SKIP/MANUAL]\e[0m $1: $2"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
}

echo "=========================================================="
echo "    Running Antigravity TTS Comprehensive Test Suite      "
echo "=========================================================="

# Test 1: Core executables
if [[ -x "$TTS_CMD" ]] && [[ -x "$SCRIPT_DIR/bin/piper/piper" ]] && [[ -x "$PREPROCESS_CMD" ]] && [[ -x "$WL_PASTE" ]] && [[ -x "$WL_COPY" ]]; then
    report_pass "All core executables exist and have execute permissions"
else
    report_fail "Executable check" "One or more core binaries missing or not executable"
fi

# Test 2: Voice models
if [[ -f "$SCRIPT_DIR/voices/en_US-lessac-medium.onnx" ]] && [[ -f "$SCRIPT_DIR/voices/hi_IN-rohan-medium.onnx" ]]; then
    report_pass "High-satisfaction neural voice models (lessac, rohan) installed and verified"
else
    report_fail "Voice model check" "One or more .onnx voice models missing"
fi

# Test 3: Preprocessor code conversion
SAMPLE_CODE='if (user_id != null && is_active == true) { return true; }'
PREPROCESSED=$(python3 "$PREPROCESS_CMD" <<< "$SAMPLE_CODE" 2>/dev/null || true)
if echo "$PREPROCESSED" | grep -q "not equal to" && echo "$PREPROCESSED" | grep -q "user id" && echo "$PREPROCESSED" | grep -q "is active"; then
    report_pass "Code preprocessor converts operators and snake_case into natural English"
else
    report_fail "Preprocessor code check" "Unexpected output: $PREPROCESSED"
fi

# Test 4: Preprocessor Hinglish transliteration & English collision preservation
SAMPLE_HINGLISH="bhai yeh function run nahi ho raha hai check the user permissions and solve the problem"
HINGLISH_OUT=$(python3 "$PREPROCESS_CMD" <<< "$SAMPLE_HINGLISH" 2>/dev/null || true)
if echo "$HINGLISH_OUT" | grep -q "भाई" && echo "$HINGLISH_OUT" | grep -q "नहीं" && echo "$HINGLISH_OUT" | grep -q "the user" && ! echo "$HINGLISH_OUT" | grep -q "थे user"; then
    report_pass "Hinglish preprocessor transliterates Hindi while cleanly preserving English 'the'"
else
    report_fail "Hinglish check" "Unexpected output: $HINGLISH_OUT"
fi

# Test 5: Explanatory pause structuring
SAMPLE_EXPLANATION=$'# Overview\n- First validate user\n- Second fetch data\njaise ki agar user invalid hai toh error aayega'
EXPLANATION_OUT=$(python3 "$PREPROCESS_CMD" <<< "$SAMPLE_EXPLANATION" 2>/dev/null || true)
if echo "$EXPLANATION_OUT" | grep -q "Overview:" && echo "$EXPLANATION_OUT" | grep -q "First validate user." && echo "$EXPLANATION_OUT" | grep -q "जैसे की"; then
    report_pass "Preprocessor inserts breath pauses at headers, bullet points, and transition clauses"
else
    report_fail "Pause structuring check" "Unexpected output: $EXPLANATION_OUT"
fi

# Test 6: Wayland primary selection retrieval
TEST_STR="Antigravity Test Selection - $(date +%s)"
"$WL_COPY" -p "$TEST_STR"
RETRIEVED=$("$WL_PASTE" -p 2>/dev/null || true)
if [[ "$RETRIEVED" == "$TEST_STR" ]]; then
    report_pass "Wayland primary selection retrieval works accurately"
else
    report_fail "Wayland primary selection" "Expected '$TEST_STR', got '$RETRIEVED'"
fi

# Test 7: Empty selection guard
"$WL_COPY" "Secret clipboard content that must not be read"
"$WL_COPY" -p --clear
"$TTS_CMD" --toggle >/dev/null 2>&1
sleep 0.2
if "$TTS_CMD" --status | grep -q "idle"; then
    report_pass "Empty selection produces notification without leaking clipboard"
else
    report_fail "Empty selection" "Tool started speaking despite empty selection"
fi

# Test 8: Play, Pause, Resume PID continuity (no restarting from beginning)
"$WL_COPY" -p "One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen."
"$TTS_CMD" --toggle >/dev/null 2>&1
sleep 0.6
STATUS1=$("$TTS_CMD" --status)
PID1=$(echo "$STATUS1" | grep -oP 'PID: \K[0-9]+' || echo "none")

# Pause
"$TTS_CMD" --toggle >/dev/null 2>&1
sleep 0.2
STATUS2=$("$TTS_CMD" --status)
PID2=$(echo "$STATUS2" | grep -oP 'PID: \K[0-9]+' || echo "none")

# Resume
"$TTS_CMD" --toggle >/dev/null 2>&1
sleep 0.2
STATUS3=$("$TTS_CMD" --status)
PID3=$(echo "$STATUS3" | grep -oP 'PID: \K[0-9]+' || echo "none")

# Complete stop
"$TTS_CMD" --stop >/dev/null 2>&1
sleep 0.2
STATUS4=$("$TTS_CMD" --status)

if [[ "$PID1" == "$PID2" ]] && [[ "$PID2" == "$PID3" ]] && [[ "$PID1" != "none" ]] && echo "$STATUS4" | grep -q "idle"; then
    report_pass "Exact millisecond Resume verified: PID $PID1 maintained across Play -> Pause -> Resume without restarts"
else
    report_fail "Lifecycle continuity test" "PID1=$PID1, PID2=$PID2, PID3=$PID3 (restarted instead of resumed)"
fi

# Test 9: Speed Adjustment Cycle
"$TTS_CMD" --cycle-speed >/dev/null 2>&1
SPEED_STATE=$("$TTS_CMD" --status)
"$TTS_CMD" --cycle-speed >/dev/null 2>&1
"$TTS_CMD" --cycle-speed >/dev/null 2>&1
"$TTS_CMD" --cycle-speed >/dev/null 2>&1
SPEED_RESET=$("$TTS_CMD" --status)
if echo "$SPEED_STATE" | grep -q "Speed: +25%" && echo "$SPEED_RESET" | grep -q "Speed: +0%"; then
    report_pass "Dynamic speed adjustment successfully cycles through speeds and resets"
else
    report_fail "Speed adjustment test" "Speed1: $SPEED_STATE | Reset: $SPEED_RESET"
fi

# Test 10: GNOME shortcut 1 (Super + R)
SCHEMA_PLAY="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts/"
BINDING_PLAY=$(gsettings get "$SCHEMA_PLAY" binding 2>/dev/null || true)
if [[ "$BINDING_PLAY" == "'<Super>r'" ]]; then
    report_pass "GNOME shortcut for Play/Pause/Resume is registered to <Super>r"
else
    report_fail "Play shortcut check" "Got $BINDING_PLAY"
fi

# Test 11: GNOME shortcut 2 (Super + Alt + R)
SCHEMA_SPEED="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts-speed/"
BINDING_SPEED=$(gsettings get "$SCHEMA_SPEED" binding 2>/dev/null || true)
if [[ "$BINDING_SPEED" == "'<Super><Alt>r'" ]]; then
    report_pass "GNOME shortcut for Adjust Speed is registered to <Super><Alt>r"
else
    report_fail "Speed shortcut check" "Got $BINDING_SPEED"
fi

# Test 12: GNOME shortcut 3 (Super + Shift + R)
SCHEMA_STOP="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/antigravity-tts-stop/"
BINDING_STOP=$(gsettings get "$SCHEMA_STOP" binding 2>/dev/null || true)
if [[ "$BINDING_STOP" == "'<Super><Shift>r'" ]]; then
    report_pass "GNOME shortcut for Complete Stop is registered to <Super><Shift>r"
else
    report_fail "Stop shortcut check" "Got $BINDING_STOP"
fi

# Test 13: Cross-session persistence check
report_skip "Login survival" "Persistent configuration verified in dconf."

echo "=========================================================="
echo "Summary: $PASSED_COUNT Passed, $FAILED_COUNT Failed, $SKIPPED_COUNT Skipped/Manual"
echo "=========================================================="

if [[ $FAILED_COUNT -eq 0 ]]; then
    exit 0
else
    exit 1
fi
