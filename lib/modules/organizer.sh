#!/bin/bash

# ==============================================================================
# Audio Tools - Organizer Module
#
# Description: Functions for scanning, organizing, and searching audio files.
# Author: CeleroLab.Com
# Copyright: (c) 2024 CeleroLab.Com
# License: MIT
# ==============================================================================

# Ensure utils are loaded
if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
    fi

scan_audios_subfolders() {
    local input_path="$1"
    local source_folder=$(get_folder_path "Enter the path of the folder to scan" "$(pwd)" "$input_path")

    if [ ! -d "$source_folder" ]; then
        log_error "Error: The specified folder does not exist."
        return 1
    fi

    local destination_folder="$source_folder/ALL_AUDIOS"
    mkdir -p "$destination_folder"

    log_info "Scanning and copying audio files to $destination_folder..."

    # Find audio files efficiently
    while IFS= read -r -d '' file; do
        local base_name
        base_name=$(basename "$file")
        local destination="$destination_folder/$base_name"
        local counter=1
        
        # Handle duplicates
        while [ -e "$destination" ]; do
            local name="${base_name%.*}"
            local extension="${base_name##*.}"
            destination="$destination_folder/${name}_${counter}.${extension}"
            ((counter++))
        done
        
        cp "$file" "$destination"
        echo "Copied: $file -> $destination" # Verbose for user
    done < <(find "$source_folder" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.wma" -o -iname "*.m4a" \) -print0)

    log_info "Process completed. All audio files have been copied to the ALL_AUDIOS folder."
}

search_and_process_audios() {
    local input_path="$1"
    local search_term="$2"
    local action_choice="$3" # d (delete) or e (extract)

    local initial_folder=$(get_folder_path "Enter the path of the folder to search" "$(pwd)" "$input_path")

    if [ ! -d "$initial_folder" ]; then
        log_error "Error: The folder '$initial_folder' does not exist."
        return 1
    fi

    if [ -z "$search_term" ]; then
        read -p "Enter the text string to search for: " search_term
    fi

    log_info "Searching for audio files containing '$search_term' in '$initial_folder'..."

    # Use array to store found files
    local found_files=()
    while IFS= read -r -d '' file; do
        found_files+=("$file")
    done < <(find "$initial_folder" -type f \( -iname "*${search_term}*.mp3" -o -iname "*${search_term}*.wav" -o -iname "*${search_term}*.ogg" -o -iname "*${search_term}*.flac" \) -print0)

    if [ ${#found_files[@]} -eq 0 ]; then
        log_info "No audio files containing '$search_term' were found."
        return 0
    fi

    log_info "${#found_files[@]} files found."

    while true; do
        local action="$action_choice"
        if [ -z "$action" ]; then
            read -p "What do you want to do? (d)elete or (e)xtract: " action
        fi

        case $action in
            [Dd]* ) 
                log_warn "WARNING: You are about to move ${#found_files[@]} files to the trash."
                read -p "Are you sure you want to proceed? (yes/no): " confirm
                if [[ $confirm == "yes" ]]; then
                    local trash_count=0
                    local to_delete_count=0
                    local fail_count=0
                    for file in "${found_files[@]}"; do
                        move_to_trash "$file" "$initial_folder"
                        case $? in
                            0) ((trash_count++));;
                            2) ((to_delete_count++));;
                            1) ((fail_count++));;
                        esac
                    done
                    log_info "Moved $trash_count files to trash."
                    break
                else
                    log_info "Operation cancelled."
                    break
                fi
                ;;
            [Ee]* )
                local destination_folder="${initial_folder}/${search_term}_extracted"
                mkdir -p "$destination_folder"
                log_info "Copying files to $destination_folder..."
                for file in "${found_files[@]}"; do
                    cp -v "$file" "$destination_folder/"
                done
                log_info "Operation completed."
                break
                ;;
            * ) 
                echo "Please answer d for delete or e for extract."
                action_choice="" # clear invalid choice to loop prompt
                ;;
        esac
    done
}
