setup() {
    load '../test_helper'
    setup_temp_dir
    LIB="$TEMP_DIR/lib"
    mkdir -p "$LIB/sub"
    cp "$FIXTURES_DIR/audio/short.wav"  "$LIB/a.wav"
    cp "$FIXTURES_DIR/audio/medium.wav" "$LIB/sub/b.wav"
}

teardown() {
    teardown_temp_dir
}

# Snapshot of the whole tree (paths only) to prove a dry run changed nothing
_tree() { (cd "$LIB" && find . | LC_ALL=C sort); }

@test "convert --dry-run leaves the tree untouched (no output folder either)" {
    before=$(_tree)
    run bash bin/audio-tools convert --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
    echo "$output" | grep -q "would convert"
}

@test "normalize --dry-run leaves the tree untouched" {
    before=$(_tree)
    run bash bin/audio-tools normalize --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
}

@test "trim-silence --dry-run leaves the tree untouched" {
    before=$(_tree)
    run bash bin/audio-tools trim-silence --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
}

@test "split-silence --dry-run leaves the tree untouched" {
    before=$(_tree)
    run bash bin/audio-tools split-silence --dry-run "$LIB/sub/b.wav"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
}

@test "scan --dry-run copies nothing and creates no folder" {
    before=$(_tree)
    run bash bin/audio-tools scan --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
    echo "$output" | grep -q "would copy"
}

@test "scan without --dry-run really copies" {
    run bash bin/audio-tools scan "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/ALL_AUDIOS/a.wav" ]
    [ -f "$LIB/ALL_AUDIOS/b.wav" ]
}

@test "search --operation extract --dry-run copies nothing and creates no folder" {
    before=$(_tree)
    run bash bin/audio-tools search a --operation extract --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
    echo "$output" | grep -qi "would copy\|would extract"
}

@test "copy_with_rename never overwrites files that share a name" {
    mkdir -p "$TEMP_DIR/dest"
    echo one > "$TEMP_DIR/one.wav"; mkdir -p "$TEMP_DIR/x"; echo two > "$TEMP_DIR/x/one.wav"
    copy_with_rename "$TEMP_DIR/one.wav" "$TEMP_DIR/dest" > /dev/null
    copy_with_rename "$TEMP_DIR/x/one.wav" "$TEMP_DIR/dest" > /dev/null
    [ "$(cat "$TEMP_DIR/dest/one.wav")" = "one" ]
    [ "$(cat "$TEMP_DIR/dest/one_1.wav")" = "two" ]
}

@test "clean --dry-run renames nothing" {
    cp "$FIXTURES_DIR/audio/short.wav" "$LIB/my song (1).wav"
    before=$(_tree)
    run bash bin/audio-tools clean --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
    echo "$output" | grep -q "my song (1).wav -> my_song_1.wav"
    echo "$output" | grep -qi "would clean"
}

@test "clean without --dry-run really renames" {
    cp "$FIXTURES_DIR/audio/short.wav" "$LIB/my song (1).wav"
    run bash bin/audio-tools clean "$LIB"
    [ "$status" -eq 0 ]
    [ -f "$LIB/my_song_1.wav" ]
    [ ! -e "$LIB/my song (1).wav" ]
}

@test "rename --dry-run renames nothing and says 'would rename'" {
    before=$(_tree)
    run bash bin/audio-tools rename --pattern 'x_{n}' --dry-run "$LIB"
    [ "$status" -eq 0 ]
    [ "$(_tree)" = "$before" ]
    echo "$output" | grep -qi "would rename"
}

@test "search JSON output is valid for a query with quotes" {
    PY=$(command -v python3 || command -v python || true)
    [ -n "$PY" ] || skip "python not available"
    run --separate-stderr bash bin/audio-tools --json search 'a"b' "$LIB"
    # no match is fine; what matters is that nothing printed is malformed JSON
    [ "$status" -eq 0 ]
    if [ -n "$output" ]; then
        echo "$output" | "$PY" -c 'import json,sys; json.load(sys.stdin)'
    fi
}
