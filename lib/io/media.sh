# Audio Tools — Media I/O (ffmpeg / ffprobe wrappers)

run_media_tool() {
    local tool="$1"; shift
    LD_LIBRARY_PATH="" "$tool" "$@"
}

media_get_duration() {
    local file="$1"
    run_media_tool ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$file" | tr -d '\r'
}

media_get_info() {
    local file="$1"
    {
        run_media_tool ffprobe -v error -show_entries \
            format=duration,bit_rate,format_name,size \
            -of default=noprint_wrappers=1 "$file"
        run_media_tool ffprobe -v error -show_entries \
            stream=codec_name,channels,sample_rate \
            -of default=noprint_wrappers=1 "$file"
    } | tr -d '\r'
}

# First audio stream property (sample_rate, channels). Empty on failure.
media_source_prop() {
    local file="$1" prop="$2"
    run_media_tool ffprobe -v error -select_streams a:0 \
        -show_entries "stream=${prop}" \
        -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | tr -d '\r' | head -n 1
}

# Print "-ar <rate>" and "-ac <channels>" (one word per line) preserving the
# source audio format. Explicit overrides win:
#   AUDIO_TOOLS_SAMPLE_RATE / AUDIO_TOOLS_CHANNELS
# Optional 2nd/3rd args cap the values for encoders with hard limits
# (e.g. MP3: 48000 Hz, 2 channels).
media_audio_args() {
    local input="$1" max_rate="${2:-}" max_ch="${3:-}"
    local rate="${AUDIO_TOOLS_SAMPLE_RATE:-}" ch="${AUDIO_TOOLS_CHANNELS:-}"
    [ -z "$rate" ] && rate=$(media_source_prop "$input" sample_rate)
    [ -z "$ch" ] && ch=$(media_source_prop "$input" channels)
    case "$rate" in ''|*[!0-9]*) rate=44100 ;; esac
    case "$ch" in ''|*[!0-9]*) ch=2 ;; esac
    if [ -n "$max_rate" ] && [ "$rate" -gt "$max_rate" ]; then rate="$max_rate"; fi
    if [ -n "$max_ch" ] && [ "$ch" -gt "$max_ch" ]; then ch="$max_ch"; fi
    printf '%s\n' -ar "$rate" -ac "$ch"
}

media_format_map() {
    local fmt="${1:-mp3}"
    case "$fmt" in
        mp3)  echo ".mp3:libmp3lame" ;;
        wav)  echo ".wav:pcm_s16le" ;;
        flac) echo ".flac:flac" ;;
        ogg)  echo ".ogg:libvorbis" ;;
        aac)  echo ".m4a:aac" ;;
        *)    echo ".mp3:libmp3lame" ;;
    esac
}

media_convert_file() {
    local input="$1" output="$2" fmt="${3:-mp3}" bitrate="${4:-320k}"
    local mapping ext codec
    mapping=$(media_format_map "$fmt")
    ext="${mapping%%:*}"
    codec="${mapping##*:}"

    if [ "$output" = "auto" ]; then
        output="${input%.*}$ext"
    fi

    local br_args=""
    case "$codec" in
        libmp3lame|libvorbis) br_args="-b:a $bitrate" ;;
        flac) br_args="-compression_level 5" ;;
        pcm_s16le|aac) br_args="-b:a $bitrate" ;;
    esac

    local ffargs=()
    ffargs+=(-v error -i "$input" -acodec "$codec")
    case "$codec" in
        libmp3lame|libvorbis) ffargs+=(-b:a "$bitrate") ;;
        flac) ffargs+=(-compression_level 5) ;;
        pcm_s16le|aac) ffargs+=(-b:a "$bitrate") ;;
    esac
    local max_rate="" max_ch=""
    case "$codec" in
        libmp3lame) max_rate=48000; max_ch=2 ;;
        aac) max_rate=96000 ;;
    esac
    local audio_args=()
    while IFS= read -r _a; do audio_args+=("$_a"); done < <(media_audio_args "$input" "$max_rate" "$max_ch")
    ffargs+=("${audio_args[@]}" "$output")
    run_media_tool ffmpeg "${ffargs[@]}"
}

media_normalize() {
    local input="$1" output="$2"
    local audio_args=()
    while IFS= read -r _a; do audio_args+=("$_a"); done < <(media_audio_args "$input")
    run_media_tool ffmpeg -v error -i "$input" \
        -af loudnorm=I=-16:LRA=11:TP=-1.5 \
        "${audio_args[@]}" "$output"
}

media_trim_silence() {
    local input="$1" output="$2"
    local audio_args=()
    while IFS= read -r _a; do audio_args+=("$_a"); done < <(media_audio_args "$input")
    run_media_tool ffmpeg -v error -i "$input" \
        -af silenceremove=start_periods=1:start_duration=0.5:start_threshold=-50dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=0.5:start_threshold=-50dB:detection=peak,aformat=dblp,areverse \
        "${audio_args[@]}" "$output"
}

media_detect_silence() {
    local input="$1" silence_dur="${2:-2}" threshold="${3:-50dB}"
    run_media_tool ffprobe -v error -show_entries \
        frame=pkt_pts_time \
        -of default=noprint_wrappers=1:nokey=1 \
        -f lavfi "amovie=$input,silencedetect=noise=-${threshold}:d=${silence_dur}"
}

media_concat() {
    local filelist="$1" output="$2"
    run_media_tool ffmpeg -v error -f concat -safe 0 -i "$filelist" \
        -ar 44100 -ac 2 "$output"
}
