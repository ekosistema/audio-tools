setup() {
    load '../test_helper'
    source "$PROJECT_ROOT/lib/cli/ui/output.sh"
    OUTPUT_FORMAT=text
    OUTPUT_QUIET=no
    setup_temp_dir
}

teardown() {
    teardown_temp_dir
}

@test "table columns fit the widest cell, header and rows alike" {
    out=$(output_table_header "NAME" "SIZE"; output_table_row "a.wav" "1KB"; output_table_row "a-much-longer-name.wav" "20MB"; output_table_footer)
    # "SIZE" lines up with the size cells of both rows
    [ "$(echo "$out" | sed -n 1p | awk '{ print index($0, "SIZE") }')" = "$(echo "$out" | sed -n 3p | awk '{ print index($0, "1KB") }')" ]
    [ "$(echo "$out" | sed -n 1p | awk '{ print index($0, "SIZE") }')" = "$(echo "$out" | sed -n 4p | awk '{ print index($0, "20MB") }')" ]
}

@test "table lines have no trailing spaces" {
    out=$(output_table_header "A" "B"; output_table_row "x" "y"; output_table_footer)
    ! echo "$out" | grep -q ' $'
}

@test "table prints a rule under the header and a total" {
    out=$(output_table_header "A" "B"; output_table_row "x" "y"; output_table_row "z" "w"; output_table_footer)
    echo "$out" | sed -n 2p | grep -q '^─* *─*'
    echo "$out" | grep -q "Total: 2 items"
}

@test "--quiet hides the total but keeps the table" {
    OUTPUT_QUIET=yes
    out=$(output_table_header "A"; output_table_row "x"; output_table_footer)
    echo "$out" | grep -q "x"
    ! echo "$out" | grep -q "Total"
}

@test "empty table still prints its header" {
    out=$(output_table_header "NAME" "SIZE"; output_table_footer)
    echo "$out" | head -n 1 | grep -q "NAME  SIZE"
    echo "$out" | grep -q "Total: 0 items"
}

@test "info prints an aligned property table" {
    cp "$FIXTURES_DIR/audio/short.wav" "$TEMP_DIR/"
    run bash bin/audio-tools info "$TEMP_DIR/short.wav"
    [ "$status" -eq 0 ]
    # every value starts in the same column as the 'Value' header
    col=$(echo "$output" | grep '^Property' | awk '{ print index($0, "Value") }')
    echo "$output" | grep -E '^(Filename|Sample Rate|Codec) ' | while read -r line; do
        [ "${line:$((col - 1)):1}" != " " ]
        [ "${line:$((col - 2)):1}" = " " ]
    done
}
