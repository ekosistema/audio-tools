setup() {
    load '../test_helper'
    setup_temp_dir
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
}

teardown() {
    teardown_temp_dir
}

# ── Destructive commands must never run unconfirmed ──

@test "remove short refuses to run without confirmation when stdin is closed" {
    run bash bin/audio-tools remove short -t 2 "$TEMP_DIR" < /dev/null
    [ "$status" -eq 64 ]
    echo "$output" | grep -q -- "--force"
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "--quiet does not bypass the delete confirmation" {
    run bash bin/audio-tools --quiet remove short -t 2 "$TEMP_DIR" < /dev/null
    [ "$status" -eq 64 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "answering 'no' keeps the files and exits 0" {
    run bash -c 'printf "no\n" | bash bin/audio-tools remove short -t 2 "$1"' _ "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "anything other than exactly 'yes' is a refusal" {
    run bash -c 'printf "y\n" | bash bin/audio-tools remove short -t 2 "$1"' _ "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "search --operation delete refuses without confirmation when stdin is closed" {
    run bash bin/audio-tools search short --operation delete "$TEMP_DIR" < /dev/null
    [ "$status" -eq 64 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "--dry-run never deletes and needs no confirmation (remove)" {
    run bash bin/audio-tools --dry-run remove short -t 2 "$TEMP_DIR" < /dev/null
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
    echo "$output" | grep -q "would move to trash"
    echo "$output" | grep -qi "dry run"
}

@test "--dry-run --force still never deletes (remove)" {
    run bash bin/audio-tools --dry-run --force remove short -t 2 "$TEMP_DIR" < /dev/null
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "--dry-run never deletes (search)" {
    run bash bin/audio-tools --dry-run search short --operation delete "$TEMP_DIR" < /dev/null
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "move_to_trash is a no-op under --dry-run" {
    AUDIO_TOOLS_DRY_RUN=yes run move_to_trash "$TEMP_DIR/short.wav" "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
    [ ! -d "$TEMP_DIR/to_delete" ]
}

# ── Non-interactive behaviour ──

@test "interactive menu with closed stdin exits 64 with a hint instead of hanging" {
    run bash bin/audio-tools < /dev/null
    [ "$status" -eq 64 ]
    echo "$output" | grep -q "stdin is closed"
}

@test "confirm_prompt honours --force without reading input" {
    AUDIO_TOOLS_FORCE=yes run confirm_prompt "Proceed?" < /dev/null
    [ "$status" -eq 0 ]
}

@test "confirm_prompt accepts exactly 'yes'" {
    run bash -c 'source lib/utils/errors.sh; printf "yes\n" | confirm_prompt "Proceed?"'
    [ "$status" -eq 0 ]
}
