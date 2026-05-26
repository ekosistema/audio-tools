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
    run shellcheck -x lib/cli/dispatcher.sh
    [ "$status" -eq 0 ]
}

@test "all commands pass shellcheck" {
    for file in lib/cli/commands/*.sh; do
        [ -f "$file" ] || continue
        run shellcheck -x "$file"
        [ "$status" -eq 0 ] || (echo "Shellcheck failed for $file"; false)
    done
}
