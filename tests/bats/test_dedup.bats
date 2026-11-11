setup() {
    load '../test_helper'
    setup_temp_dir
    # Never touch the developer's real trash: hide gio/trash-put and use a sandboxed XDG trash
    export XDG_DATA_HOME="$TEMP_DIR/xdg"
    mkdir -p "$TEMP_DIR/stubs"
    printf '#!/bin/sh\nexit 1\n' > "$TEMP_DIR/stubs/gio"
    cp "$TEMP_DIR/stubs/gio" "$TEMP_DIR/stubs/trash-put"
    chmod +x "$TEMP_DIR/stubs/gio" "$TEMP_DIR/stubs/trash-put"
    export PATH="$TEMP_DIR/stubs:$PATH"

    LIB="$TEMP_DIR/lib"
    mkdir -p "$LIB"
    cp "$FIXTURES_DIR/audio/short.wav"  "$LIB/a_original.wav"
    cp "$FIXTURES_DIR/audio/short.wav"  "$LIB/b_copy.wav"
    cp "$FIXTURES_DIR/audio/short.wav"  "$LIB/c_copy2.wav"
    cp "$FIXTURES_DIR/audio/medium.wav" "$LIB/d_unique.wav"
}

teardown() {
    teardown_temp_dir
}

# A file is "gone" from LIB and shows up in the sandboxed trash (FreeDesktop on Linux,
# ~/.Trash on macOS, where HOME is sandboxed by setup_temp_dir) or in to_delete/
_trashed() {
    [ ! -e "$LIB/$1" ] && {
        [ -e "$XDG_DATA_HOME/Trash/files/$1" ] || [ -e "$HOME/.Trash/$1" ] || [ -e "$LIB/to_delete/$1" ]
    }
}

@test "dedup moves exact duplicates to the trash and keeps the first file" {
    run bash bin/audio-tools --force dedup "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/a_original.wav" ]
    [ -f "$LIB/d_unique.wav" ]
    _trashed b_copy.wav
    _trashed c_copy2.wav
}

@test "dedup keeps the file whose path sorts first, regardless of directory order" {
    mkdir -p "$LIB/z_sub"
    cp "$FIXTURES_DIR/audio/short.wav" "$LIB/z_sub/aaa.wav"
    run bash bin/audio-tools --force dedup "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/a_original.wav" ]
    _trashed z_sub/aaa.wav || [ ! -e "$LIB/z_sub/aaa.wav" ]
}

@test "dedup --dry-run reports duplicates but moves nothing" {
    run bash bin/audio-tools --dry-run dedup "$LIB" < /dev/null
    [ "$status" -eq 0 ]
    [ -f "$LIB/b_copy.wav" ]
    [ -f "$LIB/c_copy2.wav" ]
    echo "$output" | grep -q "would move to trash"
    echo "$output" | grep -qi "dry run"
}

@test "dedup refuses to delete without confirmation when stdin is closed" {
    run bash bin/audio-tools dedup "$LIB" < /dev/null
    [ "$status" -eq 64 ]
    [ -f "$LIB/b_copy.wav" ]
    [ -f "$LIB/c_copy2.wav" ]
}

@test "dedup does nothing when the answer is not exactly 'yes'" {
    run bash -c 'printf "no\n" | bash bin/audio-tools dedup "$1"' _ "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/b_copy.wav" ]
}

@test "dedup leaves a directory without duplicates untouched" {
    rm "$LIB/b_copy.wav" "$LIB/c_copy2.wav"
    run bash bin/audio-tools --force dedup "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/a_original.wav" ]
    [ -f "$LIB/d_unique.wav" ]
    echo "$output" | grep -qi "no duplicates"
}

@test "dedup handles file names with spaces and pipes" {
    cp "$FIXTURES_DIR/audio/short.wav" "$LIB/we|rd name 1.wav"
    cp "$FIXTURES_DIR/audio/short.wav" "$LIB/we|rd name 2.wav"
    run bash bin/audio-tools --force dedup "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/a_original.wav" ]
    # of the five identical files only one survives
    [ "$(ls "$LIB"/*.wav | grep -c .)" -eq 2 ]
}

@test "find-dupes lists duplicates and never deletes" {
    run bash bin/audio-tools find-dupes "$LIB"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "keep:"
    echo "$output" | grep -q "b_copy.wav"
    [ -f "$LIB/b_copy.wav" ]
    [ -f "$LIB/c_copy2.wav" ]
}
