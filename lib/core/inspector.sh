# Audio Tools — Inspector core (info, stats, list)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t media_get_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/media.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t init_progress)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/progress.sh"
fi

audio_info() {
    local file="$1"
    if [ ! -f "$file" ]; then
        log_error "File does not exist: $file"; return 1
    fi
    local info
    info=$(media_get_info "$file" 2>/dev/null) || {
        log_error "Could not read: $file"; return 1
    }
    local duration="" bit_rate="" format_name="" codec="" channels="" sample_rate="" size=""
    while IFS= read -r line; do
        case "$line" in
            duration=*) duration="${line#*=}" ;;
            bit_rate=*) bit_rate="${line#*=}" ;;
            format_name=*) format_name="${line#*=}" ;;
            codec_name=*) codec="${line#*=}" ;;
            channels=*) channels="${line#*=}" ;;
            sample_rate=*) sample_rate="${line#*=}" ;;
            size=*) size="${line#*=}" ;;
        esac
    done <<< "$info"

    local minutes seconds
    minutes=$(echo "${duration:-0} / 60" | bc 2>/dev/null || echo "0")
    seconds=$(echo "${duration:-0} % 60" | bc 2>/dev/null || echo "0")
    local duration_str="${minutes}m${seconds}s"

    local size_hr
    size_hr=$(echo "${size:-0}" | awk '{printf "%.1f MB", $1/1048576}' 2>/dev/null || echo "${size:-0}B")

    local bitrate_str
    [ -n "$bit_rate" ] && bitrate_str="$((bit_rate / 1000))kbps" || bitrate_str="N/A"

    echo ""
    styled_echo "$DARK_GRAY" "── ${BOLD}${BRIGHT_WHITE}$(basename "$file")${NC}${DARK_GRAY} ──${NC}"
    echo -e "  ${BOLD}Format:${NC}      ${format_name:-N/A}"
    echo -e "  ${BOLD}Codec:${NC}       ${codec:-N/A}"
    echo -e "  ${BOLD}Duration:${NC}    $duration_str"
    echo -e "  ${BOLD}Bitrate:${NC}     $bitrate_str"
    echo -e "  ${BOLD}Sample rate:${NC} ${sample_rate:-N/A} Hz"
    echo -e "  ${BOLD}Channels:${NC}    ${channels:-N/A}"
    echo -e "  ${BOLD}Size:${NC}        $size_hr"
    echo ""
}

audio_stats() {
    local dir="${1:-}"
    local files=()
    while IFS= read -r -d '' file; do files+=("$file"); done < <(resolve_audio_files "$dir")
    local total=${#files[@]}
    [ "$total" -eq 0 ] && { log_warn "No audio files found."; return 0; }

    local total_duration=0 total_size=0
    declare -A format_counts format_sizes format_durations

    init_progress "$total" "Analyzing"
    for file in "${files[@]}"; do
        local info; info=$(media_get_info "$file" 2>/dev/null) || continue
        local duration=0 bit_rate=0 fname=""
        while IFS= read -r line; do
            case "$line" in
                duration=*) duration="${line#*=}" ;;
                size=*) total_size=$((total_size + ${line#*=})) ;;
                format_name=*) fname="${line#*=}" ;;
            esac
        done <<< "$info"
        duration=${duration%.*}; : "${duration:=0}"
        total_duration=$((total_duration + duration))
        [ -n "$fname" ] && format_counts[$fname]=$(( ${format_counts[$fname]:-0} + 1))
        update_progress "$(basename "$file")"
    done
    finish_progress 0 0 ""

    local dur_min=$((total_duration / 60)) dur_sec=$((total_duration % 60))
    local size_mb; size_mb=$(echo "$total_size" | awk '{printf "%.1f", $1/1048576}' 2>/dev/null || echo "0")

    echo ""
    styled_echo "$DARK_GRAY" "── ${BOLD}${BRIGHT_WHITE}Audio Stats${NC}${DARK_GRAY} ────────────────────────────────${NC}"
    echo -e "  ${BOLD}Files:${NC}        $total"
    echo -e "  ${BOLD}Total duration:${NC} ${dur_min}m ${dur_sec}s"
    echo -e "  ${BOLD}Total size:${NC}    $size_mb MB"
    echo ""
    styled_echo "$DIM" "  By format:"
    for fmt in "${!format_counts[@]}"; do
        echo -e "    ${BOLD}$fmt${NC}  ${format_counts[$fmt]} files"
    done
    echo ""
}

audio_list() {
    local dir="${1:-}"
    local files=()
    while IFS= read -r -d '' file; do files+=("$file"); done < <(resolve_audio_files "$dir" 2>/dev/null)
    local total=${#files[@]}
    [ "$total" -eq 0 ] && { log_warn "No audio files found."; return 0; }

    echo ""
    printf "  %-35s %-7s %-8s %-6s %-8s %-6s\n" "File" "Dur" "Size" "Fmt" "Bitrate" "Codec"
    styled_echo "$DARK_GRAY" "  $(printf '%0.s-' {1..80})"
    init_progress "$total" "Reading metadata"
    for file in "${files[@]}"; do
        local info; info=$(media_get_info "$file" 2>/dev/null) || continue
        local duration=0 size=0 fname="" bit_rate="" codec=""
        while IFS= read -r line; do
            case "$line" in
                duration=*) duration="${line#*=}" ;;
                size=*) size="${line#*=}" ;;
                format_name=*) fname="${line#*=}" ;;
                bit_rate=*) bit_rate="${line#*=}" ;;
                codec_name=*) codec="${line#*=}" ;;
            esac
        done <<< "$info"
        dur=${duration%.*}; : "${dur:=0}"
        local min=$((dur / 60)) sec=$((dur % 60))
        local size_kb=$((size / 1024))
        local br=""
        [ -n "$bit_rate" ] && br="$((bit_rate / 1000))k" || br="?"
        printf "  %-35s %2dm%02ds %6sK %-6s %-8s %-6s\n" "$(basename "$file")" "$min" "$sec" "$size_kb" "$fname" "$br" "$codec"
        update_progress "$(basename "$file")"
    done
    finish_progress 0 0 ""
    echo ""
    log_info "Total: $total file(s)"
}
