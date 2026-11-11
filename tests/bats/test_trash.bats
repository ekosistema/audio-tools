setup() {
    load '../test_helper'
    setup_temp_dir
    export XDG_DATA_HOME="$TEMP_DIR/xdg"
    TRASH_FILES="$XDG_DATA_HOME/Trash/files"
    TRASH_INFO="$XDG_DATA_HOME/Trash/info"
    mkdir -p "$TEMP_DIR/src"
}

teardown() {
    teardown_temp_dir
}

# Decode a percent-encoded string (printf %b understands \xNN)
_urldecode() { local s="${1//%/\\x}"; printf '%b' "$s"; }

@test "freedesktop trash moves the file and writes a valid .trashinfo" {
    echo data > "$TEMP_DIR/src/song.mp3"
    run _trash_freedesktop "$TEMP_DIR/src/song.mp3"
    [ "$status" -eq 0 ]
    [ ! -e "$TEMP_DIR/src/song.mp3" ]
    [ -f "$TRASH_FILES/song.mp3" ]
    [ -f "$TRASH_INFO/song.mp3.trashinfo" ]
    [ "$(head -n 1 "$TRASH_INFO/song.mp3.trashinfo")" = "[Trash Info]" ]
    grep -q '^Path=/' "$TRASH_INFO/song.mp3.trashinfo"
    grep -Eq '^DeletionDate=[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$' "$TRASH_INFO/song.mp3.trashinfo"
}

@test "freedesktop trash records the original absolute path so it can be restored" {
    echo data > "$TEMP_DIR/src/song.mp3"
    _trash_freedesktop "$TEMP_DIR/src/song.mp3"
    recorded=$(sed -n 's/^Path=//p' "$TRASH_INFO/song.mp3.trashinfo")
    [ "$(_urldecode "$recorded")" = "$(cd -P "$TEMP_DIR/src" && pwd)/song.mp3" ]
}

@test "freedesktop trash percent-encodes spaces and non-ASCII names" {
    echo data > "$TEMP_DIR/src/mi canción ñ.wav"
    _trash_freedesktop "$TEMP_DIR/src/mi canción ñ.wav"
    [ -f "$TRASH_FILES/mi canción ñ.wav" ]
    recorded=$(sed -n 's/^Path=//p' "$TRASH_INFO/mi canción ñ.wav.trashinfo")
    case "$recorded" in *" "*) false ;; esac
    echo "$recorded" | grep -q "%20"
    [ "$(_urldecode "$recorded")" = "$(cd -P "$TEMP_DIR/src" && pwd)/mi canción ñ.wav" ]
}

@test "two files with the same name never overwrite each other in the trash" {
    mkdir -p "$TEMP_DIR/a" "$TEMP_DIR/b"
    echo one > "$TEMP_DIR/a/track.mp3"
    echo two > "$TEMP_DIR/b/track.mp3"
    _trash_freedesktop "$TEMP_DIR/a/track.mp3"
    _trash_freedesktop "$TEMP_DIR/b/track.mp3"
    [ "$(cat "$TRASH_FILES/track.mp3")" = "one" ]
    [ "$(cat "$TRASH_FILES/track_2.mp3")" = "two" ]
    [ -f "$TRASH_INFO/track_2.mp3.trashinfo" ]
    [ "$(ls "$TRASH_FILES" | wc -l)" -eq 2 ]
}

@test "unique naming keeps dotfiles and extensionless names intact" {
    mkdir -p "$TEMP_DIR/x"
    : > "$TEMP_DIR/x/.hidden"; : > "$TEMP_DIR/x/README"
    _trash_freedesktop "$TEMP_DIR/x/.hidden"
    _trash_freedesktop "$TEMP_DIR/x/README"
    mkdir -p "$TEMP_DIR/y"
    : > "$TEMP_DIR/y/.hidden"; : > "$TEMP_DIR/y/README"
    _trash_freedesktop "$TEMP_DIR/y/.hidden"
    _trash_freedesktop "$TEMP_DIR/y/README"
    [ -e "$TRASH_FILES/.hidden_2" ]
    [ -e "$TRASH_FILES/README_2" ]
}

@test "freedesktop trash fails cleanly and leaves the file when the trash is unwritable" {
    echo data > "$TEMP_DIR/src/keep.mp3"
    export XDG_DATA_HOME="$TEMP_DIR/not-a-dir"
    : > "$XDG_DATA_HOME"
    run _trash_freedesktop "$TEMP_DIR/src/keep.mp3"
    [ "$status" -ne 0 ]
    [ -f "$TEMP_DIR/src/keep.mp3" ]
}

@test "move_to_trash never overwrites an earlier to_delete fallback file" {
    # Force the fallback path with an OS type that has no system trash
    echo one > "$TEMP_DIR/src/dup.mp3"
    OSTYPE=other run move_to_trash "$TEMP_DIR/src/dup.mp3" "$TEMP_DIR/root"
    [ "$status" -eq 2 ]
    echo two > "$TEMP_DIR/src/dup.mp3"
    OSTYPE=other run move_to_trash "$TEMP_DIR/src/dup.mp3" "$TEMP_DIR/root"
    [ "$status" -eq 2 ]
    [ "$(cat "$TEMP_DIR/root/to_delete/dup.mp3")" = "one" ]
    [ "$(cat "$TEMP_DIR/root/to_delete/dup_2.mp3")" = "two" ]
}

@test "on Linux move_to_trash ends up in the FreeDesktop trash when gio and trash-put are unavailable" {
    [[ "$OSTYPE" == linux* ]] || skip "Linux-only path"
    echo data > "$TEMP_DIR/src/gone.mp3"
    # Hide gio/trash-put by shadowing them with failing stubs first on PATH
    mkdir -p "$TEMP_DIR/bin"
    printf '#!/bin/sh\nexit 1\n' > "$TEMP_DIR/bin/gio"
    cp "$TEMP_DIR/bin/gio" "$TEMP_DIR/bin/trash-put"
    chmod +x "$TEMP_DIR/bin/gio" "$TEMP_DIR/bin/trash-put"
    PATH="$TEMP_DIR/bin:$PATH" run move_to_trash "$TEMP_DIR/src/gone.mp3" "$TEMP_DIR/root"
    [ "$status" -eq 0 ]
    [ ! -e "$TEMP_DIR/src/gone.mp3" ]
    [ -f "$TRASH_FILES/gone.mp3" ]
    [ -f "$TRASH_INFO/gone.mp3.trashinfo" ]
    [ ! -d "$TEMP_DIR/root/to_delete" ]
}

@test "move_to_trash --dry-run touches nothing and creates no trash directories" {
    echo data > "$TEMP_DIR/src/safe.mp3"
    AUDIO_TOOLS_DRY_RUN=yes run move_to_trash "$TEMP_DIR/src/safe.mp3" "$TEMP_DIR/root"
    [ "$status" -eq 0 ]
    [ -f "$TEMP_DIR/src/safe.mp3" ]
    [ ! -d "$XDG_DATA_HOME/Trash" ]
}
