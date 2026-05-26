# Audio Tools — Stats subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t audio_stats)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/inspector.sh"
fi

cmd_stats() {
    local dir="."

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Show aggregate statistics for audio files in a directory"
        echo ""
        echo "USAGE:"
        echo "  audio-tools stats [options] [directory]"
        echo ""
        echo "OPTIONS:"
        echo "  -d, --directory PATH   Directory to analyze [default: current]"
        echo "  --json                 Output in JSON format"
        echo "  -h, --help             Show this help message"
        echo ""
        echo "OUTPUT:"
        echo "  File count, total duration, total size, breakdown by format"
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            --json) export AUDIO_TOOLS_JSON="yes"; shift ;;
            --) shift; break ;;
            *) dir="$1"; shift ;;
        esac
    done

    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi
    audio_stats "$dir"
}

export -f cmd_stats
