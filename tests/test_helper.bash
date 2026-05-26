# Test helper — loads project lib files

# Resolve project root — $() may fail in WSL, use multiple fallbacks
PROJECT_ROOT=""
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"
fi
if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT" ]; then
    _helper_dir="${BASH_SOURCE[0]%/*}"
    PROJECT_ROOT="$_helper_dir/.."
    unset _helper_dir
fi
if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT/lib" ]; then
    PROJECT_ROOT="$PWD"
fi

FIXTURES_DIR="$PROJECT_ROOT/tests/fixtures"

source "$PROJECT_ROOT/lib/utils/errors.sh"
source "$PROJECT_ROOT/lib/utils/logging.sh"
source "$PROJECT_ROOT/lib/utils/config.sh"
source "$PROJECT_ROOT/lib/io/filesystem.sh"
source "$PROJECT_ROOT/lib/io/media.sh"
source "$PROJECT_ROOT/lib/io/trash.sh"
source "$PROJECT_ROOT/lib/core/converter.sh"
source "$PROJECT_ROOT/lib/core/cleaner.sh"
source "$PROJECT_ROOT/lib/core/organizer.sh"

# Auto-generate missing audio fixtures (once per shell session)
if [ -z "${_AUDIO_TOOLS_FIXTURES_GENERATED:-}" ]; then
    _AUDIO_TOOLS_FIXTURES_GENERATED=1
    for _f in short.wav medium.wav long.wav; do
        _target="$FIXTURES_DIR/audio/$_f"
        if [ ! -f "$_target" ]; then
            _dur=0; case "$_f" in short.wav) _dur=0.1 ;; medium.wav) _dur=3 ;; long.wav) _dur=10 ;; esac
            ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=mono -t "$_dur" \
                -acodec pcm_s16le "$_target" 2>/dev/null
        fi
    done
    unset _f _target _dur
fi

setup_temp_dir() {
    TEMP_DIR=$(mktemp -d -t audio-tools-test-XXXXXX 2>/dev/null)
    if [ -z "$TEMP_DIR" ] || [ ! -d "$TEMP_DIR" ]; then
        TEMP_DIR=$(mktemp -d 2>/dev/null)
    fi
    if [ -z "$TEMP_DIR" ] || [ ! -d "$TEMP_DIR" ]; then
        # Fallback: create temp dir inside project (works even when $() is broken)
        TEMP_DIR="$PROJECT_ROOT/.tmp_test.$$.$RANDOM"
        mkdir -p "$TEMP_DIR"
    fi
}

teardown_temp_dir() {
    [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}

# Count null-delimited entries in a file (avoids bats null-byte issues in $())
_count_null() {
    tr -cd '\0' < "$1" | wc -c
}
