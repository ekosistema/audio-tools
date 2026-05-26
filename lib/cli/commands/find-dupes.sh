# Audio Tools — Find Dupes subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t audio_find_dupes)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/deduper.sh"
fi

cmd_find_dupes() {
    local dir="."

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Find exact duplicate audio files by SHA256 (without deleting)"
        echo ""
        echo "USAGE:"
        echo "  audio-tools find-dupes [options] [directory]"
        echo ""
        echo "OPTIONS:"
        echo "  -d, --directory PATH   Directory to scan [default: current]"
        echo "  -h, --help             Show this help message"
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            --) shift; break ;;
            *) dir="$1"; shift ;;
        esac
    done

    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi
    audio_find_dupes "$dir"
}

export -f cmd_find_dupes
