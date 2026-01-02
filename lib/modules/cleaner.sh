#!/bin/bash

# ==============================================================================
# Audio Tools - Cleaner Module
#
# Description: Functions for cleaning audio files based on duration and filename cleanup.
# Author: CeleroLab.Com
# Copyright: (c) 2024 CeleroLab.Com
# License: MIT
# ==============================================================================

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
    fi

_process_duration_removal() {
    local mode="$1" # "short" or "long"
    local folder="$2"
    local threshold="$3"
    local confirm="$4"

    if [ ! -d "$folder" ]; then
        log_error "The specified folder does not exist."
        return 1
    fi

    check_dependency "ffprobe" || return 1

    if [[ -z "$threshold" ]]; then 
        read -p "Enter the duration threshold in seconds: " threshold
    fi
    if ! [[ "$threshold" =~ ^[0-9]+$ ]]; then
        log_error "Invalid number for duration."
        return 1
    fi

    if [[ "$confirm" != "yes" ]]; then
        log_warn "WARNING: You are about to delete $mode audio files. This is destructive."
        read -p "Are you sure you want to proceed? (yes/no): " user_confirm
        if [[ "$user_confirm" != "yes" ]]; then
            log_info "Operation cancelled."
            return 0
        fi
    fi

    local trash_count=0
    local to_delete_count=0
    local fail_count=0

    while IFS= read -r -d '' file; do
        local duration
        duration=$(run_media_tool ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
        duration=${duration%.*}
        
        : "${duration:=0}"

        local match=0
        if [[ "$mode" == "short" && "$duration" -lt "$threshold" ]]; then match=1; fi
        if [[ "$mode" == "long" && "$duration" -gt "$threshold" ]]; then match=1; fi

        if [[ "$match" -eq 1 ]]; then
            log_info "Processing: $(basename "$file") (duration: ${duration}s)"
            move_to_trash "$file" "$folder" && status=0 || status=$?
            case $status in
                0) ((trash_count++));;
                2) ((to_delete_count++));;
                *) ((fail_count++));;
            esac
        fi
    done < <(find "$folder" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.flac" \) -print0)

    log_info "Operation completed."
    log_info "$trash_count files moved to trash."
    [ $to_delete_count -gt 0 ] && log_info "$to_delete_count files moved to ${folder}/to_delete folder."
    [ $fail_count -gt 0 ] && log_error "$fail_count files could not be moved."
}

remove_short_audios() {
    local input_path="$1"
    local threshold="$2"
    local confirm="$3"
    local folder=$(get_folder_path "Enter the path to the folder containing the audio files" "$(pwd)" "$input_path")
    
    _process_duration_removal "short" "$folder" "$threshold" "$confirm"
}

remove_long_audios() {
    local input_path="$1"
    local threshold="$2"
    local confirm="$3"
    local folder=$(get_folder_path "Enter the path to the folder containing the audio files" "$(pwd)" "$input_path")

    _process_duration_removal "long" "$folder" "$threshold" "$confirm"
}

clean_filenames() {
    local input_path="$1"
    local directory=$(get_folder_path "Enter the folder path" "$(pwd)" "$input_path")

    if [ ! -d "$directory" ]; then
        log_error "The directory does not exist."
        return 1
    fi

    log_info "Cleaning filenames in: $directory"
    
    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            local dir
            dir=$(dirname "$file")
            local filename
            filename=$(basename "$file")
            
            local newname
            newname=$(echo "$filename" | sed -e 's/[^[:alnum:]\._-]//g' -e 's/ /_/g')
            
            if [ "$filename" != "$newname" ]; then
                if [ -e "$dir/$newname" ]; then
                    log_warn "Skipping rename: $newname already exists."
                else
                    mv "$file" "$dir/$newname"
                    log_info "Renamed: $filename -> $newname"
                fi
            fi
        fi
    done
    log_info "Filename cleaning completed."
}
