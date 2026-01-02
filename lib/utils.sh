#!/bin/bash

# ==============================================================================
# Audio Tools - Utils
#
# Description: Shared utility functions for logging, file handling, and media tools.
# Author: CeleroLab.Com
# Copyright: (c) 2024 CeleroLab.Com
# License: MIT
# ==============================================================================

if [ -t 2 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m' 
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

get_folder_path() {
    local prompt="$1"
    local default_path="${2:-$(pwd)}"
    local provided_path="$3"

    if [ -n "$provided_path" ]; then
        echo "$provided_path"
        return
    fi

    read -p "${prompt} (press Enter for current folder [$default_path]): " user_input
    echo "${user_input:-$default_path}"
}

check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Dependency '$cmd' not found. Please install it."
        return 1
    fi
    return 0
}

move_to_trash() {
    local file="$1"
    local fallback_root="$2"
    local to_delete_folder="${fallback_root}/to_delete"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if mv "$file" ~/.Trash/; then
            return 0
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v gio &> /dev/null; then
            if gio trash "$file"; then
                return 0
            fi
        elif command -v trash-put &> /dev/null; then
            if trash-put "$file"; then
                return 0
            fi
        else
            local trash_dir="${HOME}/.local/share/Trash/files"
            mkdir -p "$trash_dir"
            if mv "$file" "$trash_dir/"; then
                return 0
            fi
        fi
    fi

    mkdir -p "$to_delete_folder"
    if mv "$file" "$to_delete_folder/"; then
        log_warn "Failed to use system trash. File moved to $to_delete_folder instead."
        return 2
    else
        log_error "Failed to move file to trash or $to_delete_folder."
        return 1
    fi
}

run_media_tool() {
    local tool="$1"
    shift
    LD_LIBRARY_PATH="" "$tool" "$@"
}

