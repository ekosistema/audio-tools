# Audio Tools — Media I/O (ffmpeg / ffprobe wrappers)

run_media_tool() {
    local tool="$1"; shift
    LD_LIBRARY_PATH="" "$tool" "$@"
}

media_get_duration() {
    local file="$1"
    run_media_tool ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$file"
}

media_get_info() {
    local file="$1"
    run_media_tool ffprobe -v error -show_entries \
        format=duration,bit_rate,format_name,size \
        -of default=noprint_wrappers=1 "$file"
    run_media_tool ffprobe -v error -show_entries \
        stream=codec_name,channels,sample_rate \
        -of default=noprint_wrappers=1 "$file"
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
    ffargs+=(-ar 44100 -ac 2 "$output")
    run_media_tool ffmpeg "${ffargs[@]}"
}

media_normalize() {
    local input="$1" output="$2"
    run_media_tool ffmpeg -v error -i "$input" \
        -af loudnorm=I=-16:LRA=11:TP=-1.5 \
        -ar 44100 -ac 2 "$output"
}

media_trim_silence() {
    local input="$1" output="$2"
    run_media_tool ffmpeg -v error -i "$input" \
        -af silenceremove=start_periods=1:start_duration=0.5:start_threshold=-50dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=0.5:start_threshold=-50dB:detection=peak,aformat=dblp,areverse \
        -ar 44100 -ac 2 "$output"
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
