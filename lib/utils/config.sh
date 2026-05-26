# Audio Tools — Configuration
# Priority chain:  CLI flags > environment variables > config file > defaults

readonly AUDIO_TOOLS_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/audio-tools"
readonly AUDIO_TOOLS_CONFIG_FILE="${AUDIO_TOOLS_CONFIG:-$AUDIO_TOOLS_CONFIG_DIR/config.sh}"

if [ -f "$AUDIO_TOOLS_CONFIG_FILE" ]; then
    source "$AUDIO_TOOLS_CONFIG_FILE"
fi

: "${AUDIO_TOOLS_CONVERTED_DIR:=converted_mp3}"
: "${AUDIO_TOOLS_SCAN_DIR:=ALL_AUDIOS}"
: "${AUDIO_TOOLS_FORCE:=no}"
: "${AUDIO_TOOLS_FORMAT:=mp3}"
: "${AUDIO_TOOLS_BITRATE:=320k}"
