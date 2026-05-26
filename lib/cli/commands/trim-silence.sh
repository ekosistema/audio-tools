# Audio Tools — Trim Silence subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t audio_trim_silence)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/processor.sh"
fi

cmd_trim_silence() {
    local dir="."

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Remove leading and trailing silence from audio files"
        echo ""
        echo "USAGE:"
        echo "  audio-tools trim-silence [options] [directory]"
        echo ""
        echo "OPTIONS:"
        echo "  -d, --directory PATH   Source directory [default: current]"
        echo "  --dry-run              Preview without modifying"
        echo "  -h, --help             Show this help message"
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

    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi
    audio_trim_silence "$dir"
}

export -f cmd_trim_silence
