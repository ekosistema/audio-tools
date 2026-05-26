setup() {
    load '../test_helper'
    setup_temp_dir
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"   # ~0.1s
    cp "$FIXTURES_DIR/audio/medium.wav" "$TEMP_DIR/"  # 3s
    cp "$FIXTURES_DIR/audio/long.wav" "$TEMP_DIR/"    # 10s
}

teardown() {
    teardown_temp_dir
}

@test "get_short_files finds files under threshold" {
    local tmp="$BATS_TEST_TMPDIR/results"
    get_short_files "$TEMP_DIR" 1 > "$tmp"
    [ "$(_count_null "$tmp")" -eq 1 ]
}

@test "get_short_files returns empty for threshold 0" {
    local tmp="$BATS_TEST_TMPDIR/results"
    get_short_files "$TEMP_DIR" 0 > "$tmp"
    [ "$(_count_null "$tmp")" -eq 0 ]
}

@test "get_long_files finds files over threshold" {
    local tmp="$BATS_TEST_TMPDIR/results"
    get_long_files "$TEMP_DIR" 5 > "$tmp"
    [ "$(_count_null "$tmp")" -eq 1 ]
}

@test "get_long_files finds multiple files" {
    local tmp="$BATS_TEST_TMPDIR/results"
    get_long_files "$TEMP_DIR" 1 > "$tmp"
    [ "$(_count_null "$tmp")" -eq 2 ]
}

@test "get_short_files returns 1 for non-existent dir" {
    run get_short_files "$TEMP_DIR/nonexistent" 1
    [ "$status" -eq 1 ]
}

@test "get_long_files returns 1 for non-existent dir" {
    run get_long_files "$TEMP_DIR/nonexistent" 1
    [ "$status" -eq 1 ]
}

@test "get_short_files returns 1 for invalid threshold" {
    run get_short_files "$TEMP_DIR" "abc"
    [ "$status" -eq 1 ]
}

@test "clean_filenames sanitizes special characters" {
    touch "$TEMP_DIR/bad name!.wav"
    touch "$TEMP_DIR/another (copy).wav"
    run clean_filenames "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ ! -f "$TEMP_DIR/bad name!.wav" ]
    [ -f "$TEMP_DIR/bad_name.wav" ]
    [ -f "$TEMP_DIR/another_copy.wav" ]
}

@test "clean_filenames skips already clean names" {
    touch "$TEMP_DIR/clean.wav"
    run clean_filenames "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/clean.wav" ]
}

@test "clean_filenames returns 1 for non-existent dir" {
    run clean_filenames "$TEMP_DIR/nonexistent"
    [ "$status" -eq 1 ]
}

@test "get_short_files handles empty directory" {
    local empty_dir="$TEMP_DIR/empty_$$"
    mkdir -p "$empty_dir"
    local tmp="$TEMP_DIR/_results"
    get_short_files "$empty_dir" 1 > "$tmp"
    [ "$(_count_null "$tmp")" -eq 0 ]
    rm -f "$tmp"
    rmdir "$empty_dir"
}
