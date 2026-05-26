setup() {
    load '../test_helper'
    setup_temp_dir
    mkdir -p "$TEMP_DIR/sub1" "$TEMP_DIR/sub2"
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/sub1/"
    cp "$FIXTURES_DIR/audio/medium.wav" "$TEMP_DIR/sub2/"
    # Create a non-audio file that should be ignored
    echo "text" > "$TEMP_DIR/sub1/note.txt"
}

teardown() {
    teardown_temp_dir
}

@test "scan_audios_subfolders consolidates files into ALL_AUDIOS" {
    run scan_audios_subfolders "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEMP_DIR/ALL_AUDIOS" ]
    [ -f "$TEMP_DIR/ALL_AUDIOS/short.wav" ]
    [ -f "$TEMP_DIR/ALL_AUDIOS/medium.wav" ]
}

@test "scan_audios_subfolders uses custom output dir" {
    run scan_audios_subfolders "$TEMP_DIR" "$TEMP_DIR/custom"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/custom/short.wav" ]
}

@test "scan_audios_subfolders does not copy non-audio files" {
    run scan_audios_subfolders "$TEMP_DIR"
    [ ! -f "$TEMP_DIR/ALL_AUDIOS/note.txt" ]
}

@test "scan_audios_subfolders returns 1 for non-existent dir" {
    run scan_audios_subfolders "$TEMP_DIR/nonexistent"
    [ "$status" -eq 1 ]
}

@test "search_audios finds files by keyword in filename" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/sub1/kick_snare.wav"
    local tmp="$TEMP_DIR/_results"
    search_audios "$TEMP_DIR" "kick" > "$tmp"
    [ "$(_count_null "$tmp")" -eq 1 ]
    rm -f "$tmp"
}

@test "search_audios returns empty for unmatched query" {
    local tmp="$TEMP_DIR/_results"
    search_audios "$TEMP_DIR" "zzznotfound" > "$tmp"
    [ "$(_count_null "$tmp")" -eq 0 ]
    rm -f "$tmp"
}

@test "search_audios returns 1 for non-existent dir" {
    run search_audios "$TEMP_DIR/nonexistent" "test"
    [ "$status" -eq 1 ]
}

@test "search_audios returns 1 for empty query" {
    run search_audios "$TEMP_DIR" ""
    [ "$status" -eq 1 ]
}
