# Audio Tools — Processor core (normalize, trim-silence, concat, split-silence)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t media_normalize)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/media.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t init_progress)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/progress.sh"
fi

_processor_each_file() {
    local dir="$1" action_name="$2" process_fn="$3" ext_suffix="$4"
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files "$dir")
    local total=${#files[@]}
    [ "$total" -eq 0 ] && { log_warn "No audio files found."; return 0; }

    local outdir="${dir:+${dir}/}processed"
    mkdir -p "$outdir"
    log_info "Processing $total file(s)..."
    local count=0 errors=0

    init_progress "$total" "$action_name"
    for file in "${files[@]}"; do
        local filename; filename=$(basename "$file")
        local outname="${filename%.*}${ext_suffix}.${filename##*.}"
        local output="${outdir}/${outname}"

        if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
            echo "  would process: $file -> $output"
            continue
        fi

        update_progress "$filename"
        if "$process_fn" "$file" "$output" 2>/dev/null; then
            count=$((count + 1))
        else
            errors=$((errors + 1))
        fi
    done

    finish_progress "$count" "$errors" "$action_name done"
    [ "$errors" -gt 0 ] && return 1
    return 0
}

audio_normalize() {
    local dir="${1:-}"
    log_info "Normalizing audio (EBU R128 loudnorm)..."
    _processor_each_file "$dir" "Normalize" "media_normalize" "_normalized"
}

audio_trim_silence() {
    local dir="${1:-}"
    log_info "Trimming silence from audio..."
    _processor_each_file "$dir" "Trim silence" "media_trim_silence" "_trimmed"
}

audio_split_silence() {
    local file="$1"
    if [ ! -f "$file" ]; then log_error "File does not exist: $file"; return 1; fi
    local basename; basename=$(basename "$file")
    local dir; dir=$(dirname "$file")
    local name="${basename%.*}"
    local ext="${basename##*.}"
    local outdir="${dir}/${name}_split"
    mkdir -p "$outdir"

    log_info "Detecting silence in $basename..."

    local segments=()
    while IFS= read -r line; do
        [[ "$line" == *"silence_end"* ]] || continue
        local time="${line#*| }"
        time="${time%|*}"
        segments+=("$time")
    done < <(media_detect_silence "$file" 2>/dev/null)

    local total_segments=$(( ${#segments[@]} + 1 ))
    log_info "Found $total_segments segment(s) to split"

    if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
        log_info "[DRY RUN] Would split into $total_segments file(s)"
        local start=0
        for seg_end in "${segments[@]}"; do
            local seg_name="${name}_segment_0001.${ext}"
            echo "  would create: ${outdir}/${seg_name} (${start}s - ${seg_end}s)"
            start="$seg_end"
        done
        return 0
    fi

    local start=0 idx=1
    for seg_end in "${segments[@]}"; do
        local seg_name; seg_name=$(printf "${name}_segment_%04d.${ext}" "$idx")
        log_info "  [$idx/$total_segments] Extracting ${start}s - ${seg_end}s"
        run_media_tool ffmpeg -v error -i "$file" \
            -ss "$start" -to "$seg_end" -ar 44100 -ac 2 \
            "${outdir}/${seg_name}"
        start="$seg_end"
        idx=$((idx + 1))
    done

    local last_name; last_name=$(printf "${name}_segment_%04d.${ext}" "$idx")
    log_info "  [$idx/$total_segments] Extracting ${start}s - end"
    run_media_tool ffmpeg -v error -i "$file" \
        -ss "$start" -ar 44100 -ac 2 \
        "${outdir}/${last_name}"

    log_info "Split $basename into ${total_segments} segment(s) in $outdir"
}

audio_concat() {
    local dir="${1:-}"

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files "$dir")
    local total=${#files[@]}
    if [ "$total" -lt 2 ]; then
        log_error "Need at least 2 files to concatenate (found $total)"; return 1
    fi

    local filelist
    filelist=$(mktemp)
    for file in "${files[@]}"; do
        echo "file '$(realpath "$file")'" >> "$filelist"
    done

    local output="${dir:+${dir}/}concatenated.mp3"
    log_info "Concatenating $total file(s) into $output..."

    if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
        log_info "[DRY RUN] Would concatenate $total file(s) into $output"
        rm -f "$filelist"
        return 0
    fi

    if media_concat "$filelist" "$output"; then
        log_info "Created: $output"
        rm -f "$filelist"
        return 0
    else
        log_error "Failed to concatenate"
        rm -f "$filelist"
        return 1
    fi
}
