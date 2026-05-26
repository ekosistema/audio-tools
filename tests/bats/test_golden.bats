setup() {
    load '../test_helper'
    setup_temp_dir
}

teardown() {
    teardown_temp_dir
}

@test "--help matches golden file" {
    run bash bin/audio-tools --help
    [ "$status" -eq 0 ]
    echo "$output" > "$TEMP_DIR/help_output.txt"
    diff "$PROJECT_ROOT/tests/golden/help.txt" "$TEMP_DIR/help_output.txt"
}

@test "--help with NO_COLOR matches golden file" {
    run env NO_COLOR=1 bash bin/audio-tools --help
    [ "$status" -eq 0 ]
    echo "$output" > "$TEMP_DIR/help_nocolor.txt"
    diff "$PROJECT_ROOT/tests/golden/help.txt" "$TEMP_DIR/help_nocolor.txt"
}
