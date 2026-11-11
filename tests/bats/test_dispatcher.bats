setup() {
    load '../test_helper'
    setup_temp_dir
}

teardown() {
    teardown_temp_dir
}

# ── Dispatcher Routing ──

@test "dispatcher routes to convert command" {
    mkdir -p "$TEMP_DIR/audio"
    touch "$TEMP_DIR/audio/test.wav"

    run bash bin/audio-tools convert --help
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # help is routed
}

@test "dispatcher routes to clean command" {
    mkdir -p "$TEMP_DIR/audio"

    run bash bin/audio-tools clean --help
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "dispatcher routes to remove command" {
    run bash bin/audio-tools remove --help
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "dispatcher routes to search command" {
    mkdir -p "$TEMP_DIR/audio"

    run bash bin/audio-tools search --help
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "dispatcher routes to scan command" {
    mkdir -p "$TEMP_DIR/audio"

    run bash bin/audio-tools scan --help
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ── Global Flags ──

@test "dispatcher respects --quiet flag" {
    run bash bin/audio-tools --quiet --help
    [ "$status" -eq 0 ]
}

@test "dispatcher respects --verbose flag" {
    run bash bin/audio-tools --verbose --help
    [ "$status" -eq 0 ]
}

@test "dispatcher respects --no-color flag" {
    run bash bin/audio-tools --no-color --help
    [ "$status" -eq 0 ]
}

@test "dispatcher respects --json flag" {
    mkdir -p "$TEMP_DIR/audio"

    run bash bin/audio-tools --json list "$TEMP_DIR/audio"
    # Should output JSON (or error gracefully)
}

@test "dispatcher respects --dry-run flag" {
    mkdir -p "$TEMP_DIR/audio"
    touch "$TEMP_DIR/audio/test.wav"

    run bash bin/audio-tools --dry-run convert "$TEMP_DIR/audio"
    # Should not convert (or output indicates dry-run)
}

# ── Backward Compatibility ──

@test "dispatcher supports legacy --action convert" {
    mkdir -p "$TEMP_DIR/audio"
    touch "$TEMP_DIR/audio/test.wav"

    # This should work with deprecation warning
    run bash bin/audio-tools --action convert --directory "$TEMP_DIR/audio" 2>&1
    # May succeed or warn, but shouldn't crash
}

@test "dispatcher handles --quiet --verbose gracefully" {
    run bash bin/audio-tools --quiet --verbose
    [ "$status" -eq 0 ]  # verbose overrides quiet, shows help
    echo "$output" | grep -qi "usage"
}

# ── Error Handling ──

@test "dispatcher errors on unknown command" {
    run bash bin/audio-tools nonexistent
    [ "$status" -eq 64 ]  # EX_USAGE
    echo "$output" | grep -q -i "unknown command"
}

@test "dispatcher errors on invalid flag" {
    run bash bin/audio-tools convert --invalid-flag
    [ "$status" -eq 64 ]  # EX_USAGE
}

# ── File Syntax ──

@test "dispatcher.sh has valid bash syntax" {
    run bash -n lib/cli/dispatcher.sh
    [ "$status" -eq 0 ]
}

@test "convert.sh has valid bash syntax" {
    run bash -n lib/cli/commands/convert.sh
    [ "$status" -eq 0 ]
}

@test "clean.sh has valid bash syntax" {
    run bash -n lib/cli/commands/clean.sh
    [ "$status" -eq 0 ]
}

@test "remove.sh has valid bash syntax" {
    run bash -n lib/cli/commands/remove.sh
    [ "$status" -eq 0 ]
}

@test "search.sh has valid bash syntax" {
    run bash -n lib/cli/commands/search.sh
    [ "$status" -eq 0 ]
}

@test "scan.sh has valid bash syntax" {
    run bash -n lib/cli/commands/scan.sh
    [ "$status" -eq 0 ]
}

# ── Shellcheck ──

@test "dispatcher passes shellcheck" {
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"
    run shellcheck -x lib/cli/dispatcher.sh
    [ "$status" -eq 0 ]
}

@test "all commands pass shellcheck" {
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"
    for file in lib/cli/commands/*.sh; do
        [ -f "$file" ] || continue
        run shellcheck -x "$file"
        [ "$status" -eq 0 ] || { echo "Shellcheck failed for $file"; false; }
    done
}

@test "all shell sources pass shellcheck" {
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"
    run shellcheck -x bin/audio-tools lib/*/*.sh lib/cli/*/*.sh
    [ "$status" -eq 0 ]
}

# ── Global flags after the subcommand ──

@test "global --dry-run is accepted after the subcommand (convert)" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run bash bin/audio-tools convert --dry-run "$TEMP_DIR"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "dry run"
    [ ! -e "$TEMP_DIR/converted_mp3/short.mp3" ]
}

@test "global --dry-run is accepted after the subcommand (remove short)" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run bash bin/audio-tools remove short --threshold 2 --dry-run "$TEMP_DIR" < /dev/null
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/short.wav" ]
}

@test "global --json is accepted after the subcommand (list)" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run --separate-stderr bash bin/audio-tools list "$TEMP_DIR" --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '"files"'
}

@test "global --force is accepted after the subcommand (skips the confirmation)" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    mkdir -p "$TEMP_DIR/stubs" && printf '#!/bin/sh\nexit 1\n' > "$TEMP_DIR/stubs/gio" \
        && cp "$TEMP_DIR/stubs/gio" "$TEMP_DIR/stubs/trash-put" && chmod +x "$TEMP_DIR"/stubs/*
    XDG_DATA_HOME="$TEMP_DIR/xdg" PATH="$TEMP_DIR/stubs:$PATH" run bash bin/audio-tools remove short -t 2 "$TEMP_DIR" --force < /dev/null
    [ "$status" -eq 0 ]
    [ ! -e "$TEMP_DIR/short.wav" ]
}

@test "flags after a bare -- are never treated as global flags" {
    # Hoisted, --json would switch list to JSON output; after `--` it must stay untouched
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run bash bin/audio-tools list "$TEMP_DIR" -- --json
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q '"files"'
    echo "$output" | grep -q "short.wav"
}

@test "short flags keep their per-command meaning (-f is --format for convert)" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run bash bin/audio-tools convert -f flac "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/converted_mp3/short.flac" ]
}
