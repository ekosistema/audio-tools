# Audio Tools — Trash (safe deletion)
# Funnels all destructive ops through here:
#   macOS ~/.Trash  →  Linux gio trash  →  trash-put  →  ~/.local/share/Trash/files  →  to_delete/ fallback

move_to_trash() {
    local file="$1"
    local fallback_root="${2:-.}"
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
