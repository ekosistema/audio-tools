setup() {
    load '../test_helper'
    setup_temp_dir
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    cp "$FIXTURES_DIR/audio/medium.wav" "$TEMP_DIR/"
}

teardown() {
    teardown_temp_dir
}

@test "convert_to_mp3 creates converted_mp3/ with output files" {
    run convert_to_mp3 "$TEMP_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEMP_DIR/converted_mp3" ]
    [ -f "$TEMP_DIR/converted_mp3/short.mp3" ]
    [ -f "$TEMP_DIR/converted_mp3/medium.mp3" ]
}

@test "convert_to_mp3 skips already converted files" {
    mkdir -p "$TEMP_DIR/converted_mp3"
    touch "$TEMP_DIR/converted_mp3/short.mp3"
    run convert_to_mp3 "$TEMP_DIR"
    [ "$status" -eq 0 ]
    run ls "$TEMP_DIR/converted_mp3/"*.mp3 2>/dev/null
    [ "${#lines[@]}" -eq 2 ]
}

@test "convert_to_mp3 returns 1 for non-existent dir" {
    run convert_to_mp3 "$TEMP_DIR/nonexistent"
    [ "$status" -eq 1 ]
}

@test "convert_to_mp3 returns 0 for dir with no audio files" {
    local empty_dir="$TEMP_DIR/empty"
    mkdir -p "$empty_dir"
    run convert_to_mp3 "$empty_dir"
    [ "$status" -eq 0 ]
}

@test "convert_to_mp3 uses custom output dir" {
    run convert_to_mp3 "$TEMP_DIR" "$TEMP_DIR/custom_out"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/custom_out/short.mp3" ]
}

@test "convert_to_mp3 produces valid mp3 files" {
    run convert_to_mp3 "$TEMP_DIR"
    [ "$status" -eq 0 ]
    local duration
    duration=$(run_media_tool ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$TEMP_DIR/converted_mp3/short.mp3")
    [[ -n "$duration" ]]
}
