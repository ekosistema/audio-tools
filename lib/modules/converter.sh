#!/bin/bash

# ==============================================================================
# Audio Tools - Converter Module
#
# Description: Functions for converting audio files to MP3 format.
# Author: CeleroLab.Com
# Copyright: (c) 2024 CeleroLab.Com
# License: MIT
# ==============================================================================

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
    fi

convert_to_mp3() {
    local input_path="$1"
    local source_folder=$(get_folder_path "Enter the path to the folder containing the audio files" "$(pwd)" "$input_path")

    if [ ! -d "$source_folder" ]; then
        log_error "The specified folder does not exist: $source_folder"
        return 1
    fi

    check_dependency "ffmpeg" || return 1

    local output_folder="${source_folder}/converted_mp3"
    mkdir -p "$output_folder"

    log_info "Starting conversion in: $source_folder"

    shopt -s nullglob
    local files=("$source_folder"/*.wav "$source_folder"/*.ogg "$source_folder"/*.flac)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        log_warn "No suitable audio files (wav, ogg, flac) found in $source_folder"
        return 0
    fi

    for file in "${files[@]}"; do
        [ -e "$file" ] || continue
        log_info "Converting: $(basename "$file")"
        local output_file="${output_folder}/$(basename "${file%.*}").mp3"
        run_media_tool ffmpeg -v error -i "$file" -acodec libmp3lame -b:a 320k -ar 44100 -ac 2 "$output_file" || log_error "Failed to convert: $(basename "$file")"
    done

    log_info "Conversion completed. MP3 files are located in: $output_folder"
}
