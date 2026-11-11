setup() {
    load '../test_helper'
    setup_temp_dir
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    ESC=$'\033'
    unset NO_COLOR CLICOLOR_FORCE AUDIO_TOOLS_COLOR AUDIO_TOOLS_NO_COLOR
    # CI runners export TERM=dumb, which (by design) disables color; pin a real terminal
    export TERM=xterm-256color
}

teardown() {
    teardown_temp_dir
}

# Count escape characters in a string
_esc_count() { printf '%s' "$1" | tr -cd '\033' | wc -c; }

@test "no color by default when output is not a terminal" {
    run bash bin/audio-tools list "$TEMP_DIR" --format table
    [ "$status" -eq 0 ]
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "--color=always forces color even when piped" {
    run bash bin/audio-tools --color=always list "$TEMP_DIR" --format table
    [ "$status" -eq 0 ]
    [ "$(_esc_count "$output")" -gt 0 ]
}

@test "--color (no value) means always" {
    run bash bin/audio-tools --color list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -gt 0 ]
}

@test "--color works after the subcommand too" {
    run bash bin/audio-tools list "$TEMP_DIR" --format table --color=always
    [ "$(_esc_count "$output")" -gt 0 ]
}

@test "AUDIO_TOOLS_COLOR=always and CLICOLOR_FORCE=1 force color" {
    AUDIO_TOOLS_COLOR=always run bash bin/audio-tools list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -gt 0 ]
    CLICOLOR_FORCE=1 run bash bin/audio-tools list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -gt 0 ]
}

@test "--color=never wins over AUDIO_TOOLS_COLOR=always" {
    AUDIO_TOOLS_COLOR=always run bash bin/audio-tools --color=never list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "NO_COLOR beats --color=always" {
    NO_COLOR=1 run bash bin/audio-tools --color=always list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "--no-color beats --color=always" {
    run bash bin/audio-tools --color=always --no-color list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "TERM=dumb disables color" {
    TERM=dumb run bash bin/audio-tools --color=always list "$TEMP_DIR" --format table
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "--json is never colored" {
    run --separate-stderr bash bin/audio-tools --color=always --json list "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "invalid --color value is a usage error" {
    run bash bin/audio-tools --color=rainbow list "$TEMP_DIR"
    [ "$status" -eq 64 ]
    echo "$output" | grep -q "auto, always or never"
}

@test "log lines on stderr are colored independently of stdout" {
    run --separate-stderr bash bin/audio-tools --color=always convert --dry-run "$TEMP_DIR"
    [ "$(_esc_count "$stderr")" -gt 0 ]
}

@test "colored table keeps its columns aligned (escape codes do not count as width)" {
    cp "$FIXTURES_DIR/audio/medium.wav" "$TEMP_DIR/a-longer-name.wav"
    run bash bin/audio-tools --color=always list "$TEMP_DIR" --format table
    plain=$(printf '%s' "$output" | sed -E 's/\x1b\[[0-9;]*m//g')
    run bash bin/audio-tools --no-color list "$TEMP_DIR" --format table
    [ "$plain" = "$output" ]
}

@test "interactive menu is colored when asked and readable once stripped" {
    run bash -c 'printf "0\n" | AUDIO_TOOLS_COLOR=always TERM=xterm bash bin/audio-tools'
    [ "$status" -eq 0 ]
    [ "$(_esc_count "$output")" -gt 0 ]
    plain=$(printf '%s' "$output" | sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g')
    echo "$plain" | grep -q "Audio Tools v"
    echo "$plain" | grep -q "CONVERSION & PROCESSING"
    echo "$plain" | grep -q "10)  Find duplicates"
}

@test "interactive menu has no color codes of its own when piped" {
    run bash -c 'printf "0\n" | TERM=dumb bash bin/audio-tools'
    [ "$status" -eq 0 ]
    [ "$(_esc_count "$output")" -eq 0 ]
}

@test "dry-run lines are highlighted but stay greppable once stripped" {
    run bash bin/audio-tools --color=always --dry-run remove short --threshold 2 "$TEMP_DIR" < /dev/null
    [ "$status" -eq 0 ]
    plain=$(printf '%s' "$output" | sed -E 's/\x1b\[[0-9;]*m//g')
    echo "$plain" | grep -q "would move to trash: .*short.wav"
}
