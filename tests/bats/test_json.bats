setup() {
    load '../test_helper'
    source "$PROJECT_ROOT/lib/cli/ui/output.sh"
    setup_temp_dir
    PY=$(command -v python3 || command -v python || true)
}

teardown() {
    teardown_temp_dir
}

# Validate stdin as JSON; exits non-zero when invalid.
_valid_json() { "$PY" -c 'import json,sys; json.load(sys.stdin)'; }
# Print a value of the parsed JSON (python expression over `d`), no trailing newline.
_json_get() { "$PY" -c "import json,sys; d=json.load(sys.stdin); sys.stdout.buffer.write(str($1).encode())"; }

@test "json_escape handles quotes, backslashes and whitespace controls" {
    out=$(json_escape $'a"b\\c\nd\te')
    [ "$out" = 'a\"b\\c\nd\te' ]
}

@test "json_escape encodes other control characters as \\u00XX" {
    out=$(json_escape $'x\x01y')
    [ "$out" = 'x\u0001y' ]
}

@test "json_escape leaves UTF-8 untouched" {
    out=$(json_escape 'canción ñ 音楽')
    [ "$out" = 'canción ñ 音楽' ]
}

@test "json_number accepts numbers and maps junk to null" {
    [ "$(json_number 12)" = "12" ]
    [ "$(json_number 3.50)" = "3.50" ]
    [ "$(json_number '')" = "null" ]
    [ "$(json_number N/A)" = "null" ]
    [ "$(json_number 1.2.3)" = "null" ]
}

@test "output_success/warning/error emit valid JSON for hostile messages" {
    [ -n "$PY" ] || skip "python not available"
    OUTPUT_FORMAT=json
    msg=$'He said "hi" \\ and\nleft'
    output_success "$msg" | _valid_json
    output_warning "$msg" | _valid_json
    output_error "$msg" 2>&1 | _valid_json
    [ "$(output_success "$msg" | _json_get "d['message']")" = "$msg" ]
}

@test "output_json escapes keys and values" {
    [ -n "$PY" ] || skip "python not available"
    output_json 'k"ey' 'a=b"c' 'p=C:\dir' | _valid_json
    [ "$(output_json k 'p=C:\dir' | _json_get "d['k']['p']")" = 'C:\dir' ]
}

@test "table JSON keeps rows as arrays of cells" {
    [ -n "$PY" ] || skip "python not available"
    OUTPUT_FORMAT=json
    out=$(output_table_header "NAME" "SIZE"; output_table_row 'a "q".mp3' "1KB"; output_table_row "b.wav" "2KB"; output_table_footer)
    echo "$out" | _valid_json
    [ "$(echo "$out" | _json_get "len(d['rows'])")" = "2" ]
    [ "$(echo "$out" | _json_get "d['rows'][0][0]")" = 'a "q".mp3' ]
    [ "$(echo "$out" | _json_get "d['rows'][1][1]")" = "2KB" ]
}

@test "list --json is valid JSON with hostile file names" {
    [ -n "$PY" ] || skip "python not available"
    mkdir -p "$TEMP_DIR/lib"
    # Some filesystems (Windows) cannot hold quotes in names: fall back to other odd characters
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/lib/it's \"quoted\" back.wav" 2>/dev/null \
        || cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/lib/it's \$odd & name.wav"
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/lib/música ñ.wav"
    run --separate-stderr bash bin/audio-tools --json list "$TEMP_DIR/lib"
    [ "$status" -eq 0 ]
    echo "$output" | _valid_json
    [ "$(echo "$output" | _json_get "len(d['files'])")" = "2" ]
    [ "$(echo "$output" | _json_get "d['summary']['total']")" = "2" ]
}
