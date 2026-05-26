setup() {
    load '../test_helper'
    setup_temp_dir
}

teardown() {
    teardown_temp_dir
}

# ── Help & Version ──

@test "--help exits 0 and shows usage" {
    run bash bin/audio-tools --help
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "USAGE"
}

@test "--help contains all command sections" {
    run bash bin/audio-tools --help
    echo "$output" | grep -q "CONVERSION"
    echo "$output" | grep -q "CLEANUP & ORGANIZE"
    echo "$output" | grep -q "INSPECT & SEARCH"
    echo "$output" | grep -q "convert"
    echo "$output" | grep -q "remove-short"
    echo "$output" | grep -q "completion"
}

@test "-h is alias for --help" {
    run bash bin/audio-tools -h
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "USAGE"
}

@test "--version prints version string" {
    run bash bin/audio-tools --version
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "audio-tools v"
}

@test "-V prints version string" {
    run bash bin/audio-tools -V
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "audio-tools v"
}

# ── Subcommand dispatch ──

@test "no args launches interactive menu (0 to exit)" {
    printf '0\n' > "$TEMP_DIR/input.txt"
    run bash bin/audio-tools < "$TEMP_DIR/input.txt"
    [ "$status" -eq 0 ]
}

@test "invalid command exits 64" {
    run bash bin/audio-tools nonexistent
    [ "$status" -eq 64 ]
}

@test "convert with nonexistent directory exits 74" {
    run bash bin/audio-tools convert --directory "$TEMP_DIR/nonexistent"
    [ "$status" -eq 74 ]
}

# ── Required flags per command ──

@test "remove-short without threshold exits 64" {
    run bash bin/audio-tools remove-short --directory "$TEMP_DIR"
    [ "$status" -eq 64 ]
}

@test "remove-long without threshold exits 64" {
    run bash bin/audio-tools remove-long --directory "$TEMP_DIR"
    [ "$status" -eq 64 ]
}

@test "search without query exits 64" {
    run bash bin/audio-tools search --operation delete
    [ "$status" -eq 64 ]
}

@test "search without operation lists matches (no error)" {
    touch "$TEMP_DIR/test_file.wav"
    run bash bin/audio-tools search --query test --directory "$TEMP_DIR"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "test_file.wav"
}

# ── Flags ──

@test "--force flag is accepted" {
    run bash bin/audio-tools clean --directory "$TEMP_DIR" --force
    [ "$status" -eq 0 ]
}

@test "--no-force flag is accepted" {
    run bash bin/audio-tools --no-force clean --directory "$TEMP_DIR"
    [ "$status" -eq 0 ]
}

@test "NO_COLOR suppresses ANSI escape codes" {
    run env NO_COLOR=1 bash bin/audio-tools --help
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q $'\033'
}

@test "--quiet suppresses info output" {
    run bash bin/audio-tools --quiet convert --directory "$TEMP_DIR"
    ! echo "$output" | grep -q "\[INFO\]"
}

@test "--verbose overrides --quiet" {
    run bash bin/audio-tools --quiet --verbose convert --directory "$TEMP_DIR"
    [ "$status" -eq 0 ]
}

# ── Completion ──

@test "completion bash generates script" {
    run bash bin/audio-tools completion bash
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "_audio_tools_complete"
    echo "$output" | grep -q "complete -F"
}

@test "completion zsh generates script" {
    run bash bin/audio-tools completion zsh
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "#compdef audio-tools"
}

@test "completion fish generates script" {
    run bash bin/audio-tools completion fish
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "complete -c audio-tools"
}

@test "completion with invalid shell exits 64" {
    run bash bin/audio-tools completion invalid
    [ "$status" -eq 64 ]
}

# ── Edge cases ──

@test "directory with spaces is handled" {
    local spacedir="$TEMP_DIR/my samples"
    mkdir -p "$spacedir"
    cp "$FIXTURES_DIR/audio/short.wav" "$spacedir/"
    run bash bin/audio-tools convert --directory "$spacedir"
    [ "$status" -eq 0 ]
}

@test "unknown option exits 64" {
    run bash bin/audio-tools --bogus
    [ "$status" -eq 64 ]
}

@test "unknown option after command exits 64" {
    run bash bin/audio-tools convert --bogus
    [ "$status" -eq 64 ]
}

# ── Positional file arguments ──

@test "info accepts positional file" {
    run bash bin/audio-tools info "$FIXTURES_DIR/audio/short.wav"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "duration"
}

@test "info rejects non-existent positional file" {
    run bash bin/audio-tools info "$FIXTURES_DIR/audio/nonexistent.wav"
    [ "$status" -eq 64 ]
}

@test "convert accepts positional single file" {
    run bash bin/audio-tools convert "$FIXTURES_DIR/audio/short.wav"
    [ "$status" -eq 0 ]
}

@test "convert accepts multiple positional files" {
    run bash bin/audio-tools convert "$FIXTURES_DIR/audio/short.wav" "$FIXTURES_DIR/audio/medium.wav"
    [ "$status" -eq 0 ]
}

@test "convert accepts positional dir (scans recursively)" {
    run bash bin/audio-tools convert "$FIXTURES_DIR/audio"
    [ "$status" -eq 0 ]
}

@test "convert with non-existent positional path warns" {
    run bash bin/audio-tools convert "$FIXTURES_DIR/audio/nonexistent.wav"
    [ "$status" -eq 74 ]
    echo "$output" | grep -qi "not found"
}

@test "stats accepts positional files" {
    run bash bin/audio-tools stats "$FIXTURES_DIR/audio/short.wav" "$FIXTURES_DIR/audio/medium.wav"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "file"
}

@test "list accepts positional directory" {
    run bash bin/audio-tools list "$FIXTURES_DIR/audio"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "short.wav"
}

@test "convert rejects non-audio positional file" {
    local tmpfile; tmpfile="$PROJECT_ROOT/tests/fixtures/non_audio_test.txt"
    echo "not audio" > "$tmpfile"
    run bash bin/audio-tools convert "$tmpfile"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "not a valid audio"
    rm -f "$tmpfile"
}

@test "mixed positional files and --directory (additive)" {
    run bash bin/audio-tools convert "$FIXTURES_DIR/audio/medium.wav" --directory "$FIXTURES_DIR/audio"
    [ "$status" -eq 0 ]
}

@test "normalize accepts positional files" {
    run bash bin/audio-tools normalize "$FIXTURES_DIR/audio/short.wav"
    [ "$status" -eq 0 ]
}

@test "concat rejects single positional file (needs >=2)" {
    run bash bin/audio-tools concat "$FIXTURES_DIR/audio/short.wav"
    [ "$status" -eq 1 ]
    echo "$output" | grep -qi "need at least 2"
}

@test "find-dupes accepts positional files" {
    run bash bin/audio-tools find-dupes "$FIXTURES_DIR/audio/short.wav" "$FIXTURES_DIR/audio/medium.wav"
    [ "$status" -eq 0 ]
}

@test "dedup accepts positional files (dry-run)" {
    run bash bin/audio-tools dedup --dry-run "$FIXTURES_DIR/audio/short.wav" "$FIXTURES_DIR/audio/medium.wav"
    [ "$status" -eq 0 ]
}

@test "remove-short accepts positional file" {
    run bash bin/audio-tools --force remove-short --threshold 9999 "$FIXTURES_DIR/audio/short.wav"
    [ "$status" -eq 0 ]
}

@test "search accepts positional directory" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run bash bin/audio-tools --force search --query short --operation delete "$TEMP_DIR"
    [ "$status" -eq 0 ]
}
