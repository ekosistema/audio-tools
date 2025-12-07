#!/bin/bash

# ==============================================================================
# Audio Tools - Utils
#
# Description: Shared utility functions for logging, file handling, and media tools.
# Author: CeleroLab.Com
# Copyright: (c) 2024 CeleroLab.Com
# License: MIT
# ==============================================================================

# Log helpers
log_info() { echo -e "[INFO] $1"; }
log_warn() { echo -e "[WARN] $1"; }
log_error() { echo -e "[ERROR] $1" >&2; }

# Function to get folder path from user or argument
# Usage: get_folder_path "Prompt message" [optional_default_path] [optional_provided_path]
get_folder_path() {
    local prompt="$1"
    local default_path="${2:-$(pwd)}"
    local provided_path="$3"

    if [ -n "$provided_path" ]; then
        echo "$provided_path"
        return
    fi

    # Interactive mode
    read -p "${prompt} (press Enter for current folder [$default_path]): " user_input
    echo "${user_input:-$default_path}"
}

# Function to check dependencies
check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Dependency '$cmd' not found. Please install it."
        return 1
    fi
    return 0
}

# Function to move a file to trash or fallback folder
move_to_trash() {
    local file="$1"
    local fallback_root="$2"
    local to_delete_folder="${fallback_root}/to_delete"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if mv "$file" ~/.Trash/; then
            return 0
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v gio &> /dev/null; then
            # GNOME
            if gio trash "$file"; then
                return 0
            fi
        elif command -v trash-put &> /dev/null; then
            # trash-cli
            if trash-put "$file"; then
                return 0
            fi
        else
            # XDG Trash Fallback (Simplified)
            local trash_dir="${HOME}/.local/share/Trash/files"
            mkdir -p "$trash_dir"
            if mv "$file" "$trash_dir/"; then
                return 0
            fi
        fi
    fi

    # Fallback to local to_delete folder
    mkdir -p "$to_delete_folder"
    if mv "$file" "$to_delete_folder/"; then
        log_warn "Failed to use system trash. File moved to $to_delete_folder instead."
        return 2
    else
        log_error "Failed to move file to trash or $to_delete_folder."
        return 1
    fi
}

# Wrapper to run media tools (ffmpeg, ffprobe) safely
# Unsets LD_LIBRARY_PATH to avoid conflicts with Conda/Anaconda environments which often break system tools.
run_media_tool() {
    local tool="$1"
    shift
    LD_LIBRARY_PATH="" "$tool" "$@"
}

