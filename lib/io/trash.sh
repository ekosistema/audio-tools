# Audio Tools — Trash (safe deletion)
# Funnels all destructive ops through here. Order of attempts:
#   macOS:        ~/.Trash (unique name, never overwrites)
#   Linux / WSL:  gio trash  ->  trash-put  ->  FreeDesktop Trash spec (files + .trashinfo)
#   anything else, or when all of the above fail: <dir>/to_delete/
#
# The FreeDesktop fallback writes ~/.local/share/Trash/{files,info} exactly like a
# desktop environment would, so files stay restorable from Nautilus/Dolphin,
# `gio trash --restore` or `trash-restore` even on a headless box or WSL.

# Verb for result messages: honest about dry runs.
delete_verb() {
    if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
        printf '[dry run] Would delete'
    else
        printf 'Deleted'
    fi
}

# Percent-encode a path for the Trash spec's "Path=" key (RFC 3986 unreserved + "/").
_trash_urlencode() {
    local LC_ALL=C
    local s="$1" out="" ch i
    for ((i = 0; i < ${#s}; i++)); do
        ch="${s:i:1}"
        case "$ch" in
            [a-zA-Z0-9/._~-]) out+="$ch" ;;
            *) printf -v ch '%%%02X' "'$ch"; out+="$ch" ;;
        esac
    done
    printf '%s' "$out"
}

# Print a name that does not exist in any of the given directories.
# "song.mp3" -> "song.mp3", then "song_2.mp3", "song_3.mp3", ...
_trash_unique_name() {
    local base="$1"; shift
    local stem="${base%.*}" ext=""
    [ "$stem" != "$base" ] && ext=".${base##*.}"
    # Dotfiles ("." + name, no real extension) keep the whole name as stem
    [ -z "$stem" ] && { stem="$base"; ext=""; }
    local name="$base" n=2 dir taken
    while :; do
        taken=no
        for dir in "$@"; do
            [ -e "$dir/$name" ] || [ -L "$dir/$name" ] && taken=yes
            [ -e "$dir/$name.trashinfo" ] && taken=yes
        done
        [ "$taken" = no ] && break
        name="${stem}_${n}${ext}"
        n=$((n + 1))
    done
    printf '%s' "$name"
}

# FreeDesktop.org Trash spec (home trash). Returns 0 on success.
_trash_freedesktop() {
    local file="$1"
    local data_home="${XDG_DATA_HOME:-${HOME:-}/.local/share}"
    [ -n "${HOME:-}${XDG_DATA_HOME:-}" ] || return 1
    local trash_root="$data_home/Trash"
    local files_dir="$trash_root/files" info_dir="$trash_root/info"
    mkdir -p "$files_dir" "$info_dir" 2>/dev/null || return 1
    chmod 700 "$trash_root" 2>/dev/null || true

    local abs
    abs="$(cd -P "$(dirname "$file")" 2>/dev/null && pwd)/$(basename "$file")" || return 1

    local name; name=$(_trash_unique_name "$(basename "$file")" "$files_dir" "$info_dir")
    local info="$info_dir/$name.trashinfo"

    # Write the info file first (spec): an orphan file in files/ would be unrestorable
    {
        printf '[Trash Info]\n'
        printf 'Path=%s\n' "$(_trash_urlencode "$abs")"
        printf 'DeletionDate=%s\n' "$(date +%Y-%m-%dT%H:%M:%S)"
    } > "$info" 2>/dev/null || return 1

    if mv -- "$file" "$files_dir/$name" 2>/dev/null; then
        return 0
    fi
    rm -f "$info"
    return 1
}

move_to_trash() {
    local file="$1"
    local fallback_root="${2:-.}"
    local to_delete_folder="${fallback_root}/to_delete"

    # Single chokepoint for destructive operations: --dry-run must never move anything.
    if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
        printf '  %bwould move to trash:%b %s\n' "${YELLOW:-}" "${NC:-}" "$file"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        local mac_trash="${HOME}/.Trash"
        mkdir -p "$mac_trash" 2>/dev/null
        local mac_name; mac_name=$(_trash_unique_name "$(basename "$file")" "$mac_trash")
        if mv -- "$file" "$mac_trash/$mac_name" 2>/dev/null; then
            return 0
        fi
    elif [[ "$OSTYPE" == linux* ]]; then
        if command -v gio >/dev/null 2>&1 && gio trash -- "$file" 2>/dev/null; then
            return 0
        fi
        if command -v trash-put >/dev/null 2>&1 && trash-put -- "$file" 2>/dev/null; then
            return 0
        fi
        if _trash_freedesktop "$file"; then
            return 0
        fi
    fi

    mkdir -p "$to_delete_folder"
    local fb_name; fb_name=$(_trash_unique_name "$(basename "$file")" "$to_delete_folder")
    if mv -- "$file" "$to_delete_folder/$fb_name"; then
        log_warn "Could not use the system trash. File moved to $to_delete_folder instead."
        return 2
    else
        log_error "Failed to move file to trash or $to_delete_folder."
        return 1
    fi
}
