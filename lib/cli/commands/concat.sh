# Audio Tools — Concat subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t audio_concat)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/processor.sh"
fi

cmd_concat() {
    local dir="."

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Concatenate multiple audio files into one"
        echo ""
        echo "USAGE:"
        echo "  audio-tools concat [options] [directory]"
        echo ""
        echo "OPTIONS:"
        echo "  -d, --directory PATH   Directory with audio files [default: current]"
        echo "  --dry-run              Preview without modifying"
        echo "  -h, --help             Show this help message"
        echo ""
        echo "NOTES:"
        echo "  Requires at least 2 audio files in the directory."
        echo "  Files are concatenated in alphabetical order."
        echo "  Output: concatenated.mp3"
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            --dry-run) export AUDIO_TOOLS_DRY_RUN="yes"; shift ;;
            --) shift; break ;;
            *) dir="$1"; shift ;;
        esac
    done

    export AUDIO_TOOLS_DIRECTORY="$dir"
    audio_concat "$dir"
}

export -f cmd_concat
