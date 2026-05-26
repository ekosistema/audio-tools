# Audio Tools — Interactive TUI (Terminal User Interface)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t styled_echo)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi

CURSOR_HIDE="\033[?25l"
CURSOR_SHOW="\033[?25h"

show_main_menu() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    Audio Tools v3.0.0                        ║
║         Batch process audio files with confidence            ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo ""
    styled_echo "$BOLD" "CONVERSION & PROCESSING"
    echo "  1)  Convert audio (any format → mp3/ogg/aac/flac)"
    echo "  2)  Normalize loudness (EBU R128 -16 LUFS)"
    echo "  3)  Trim silence (remove start/end silence)"
    echo "  4)  Concatenate files (join multiple files)"
    echo "  5)  Split at silence (segment a file)"
    echo ""
    styled_echo "$BOLD" "CLEANUP & ORGANIZE"
    echo "  6)  Sanitize filenames"
    echo "  7)  Rename files with patterns"
    echo "  8)  Scan & consolidate from subfolders"
    echo "  9)  Remove short/long files"
    echo ""
    styled_echo "$BOLD" "DEDUPLICATION"
    echo " 10)  Find duplicates (SHA256, keep files)"
    echo " 11)  Dedup & remove duplicates (SHA256)"
    echo ""
    styled_echo "$BOLD" "INSPECT & SEARCH"
    echo " 12)  List all audio files"
    echo " 13)  Stats (directory statistics)"
    echo " 14)  Show file metadata"
    echo " 15)  Search & extract/delete files"
    echo ""
    echo "  c)   Configuration"
    echo "  h)   Help"
    echo ""
    echo "  0)   Exit"
    echo ""
    echo "  ─────────────────────────────────────────────────────"
    echo "  Maintained by CeleroLab — https://celerolab.com"
    echo ""
}

run_interactive_menu() {
    while true; do
        show_main_menu
        read -p "Enter your choice: " choice

        case "$choice" in
            1) menu_convert ;;
            2) menu_normalize ;;
            3) menu_trim_silence ;;
            4) menu_concat ;;
            5) menu_split_silence ;;
            6) menu_clean ;;
            7) menu_rename ;;
            8) menu_scan ;;
            9) menu_remove ;;
            10) menu_find_dupes ;;
            11) menu_dedup ;;
            12) menu_list ;;
            13) menu_stats ;;
            14) menu_info ;;
            15) menu_search ;;
            c|C) menu_config ;;
            h|H) show_tui_help ;;
            0) echo "Goodbye!"; return 0 ;;
            *) echo "Invalid choice. Please try again."; sleep 1 ;;
        esac
    done
}

show_tui_help() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                    Help                            ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Audio Tools lets you batch process audio files from the terminal."
    echo ""
    echo "COMMANDS (can also be used directly from CLI):"
    echo ""
    echo "  audio-tools convert      Convert audio formats"
    echo "  audio-tools normalize    EBU R128 loudness normalization"
    echo "  audio-tools trim-silence Remove silence from start/end"
    echo "  audio-tools concat       Join audio files"
    echo "  audio-tools split-silence Split at silence points"
    echo "  audio-tools clean        Sanitize filenames"
    echo "  audio-tools rename       Batch rename with patterns"
    echo "  audio-tools scan         Consolidate from subfolders"
    echo "  audio-tools remove       Remove short/long files"
    echo "  audio-tools dedup        Remove duplicates"
    echo "  audio-tools find-dupes   Find duplicates (keep files)"
    echo "  audio-tools list         List files with metadata"
    echo "  audio-tools stats        Directory statistics"
    echo "  audio-tools info         File metadata"
    echo "  audio-tools search       Search by keyword"
    echo "  audio-tools config       Configuration"
    echo ""
    echo "GLOBAL FLAGS:"
    echo "  --dry-run    Preview without modifying files"
    echo "  --force      Skip confirmation prompts"
    echo "  --dir PATH   Target directory"
    echo ""
    echo "For detailed help: audio-tools <command> --help"
    echo ""
    read -p "Press Enter to continue..."
}

_tui_prompt_path() {
    local var_name="$1" prompt="$2" user_path
    read -e -p "$prompt " user_path
    user_path="${user_path%"${user_path##*[![:space:]]}"}"
    user_path="${user_path:-.}"
    if [ ! -e "$user_path" ]; then
        echo "Path not found!"
        sleep 2
        return 1
    fi
    eval "$var_name=\"\$user_path\""
    return 0
}

menu_convert() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Convert Audio                            ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    read -p "Output format (mp3/ogg/aac/flac) [mp3]: " format
    format="${format:-mp3}"
    read -p "Bitrate (192k/256k/320k) [320k]: " bitrate
    bitrate="${bitrate:-320k}"
    read -p "Output directory name [converted_mp3]: " output
    output="${output:-converted_mp3}"
    echo ""
    echo "Converting audio in: $dir"
    echo "Format: $format, Bitrate: $bitrate"
    echo "Output: $output"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" convert "$dir" -f "$format" -b "$bitrate" -o "$output"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_normalize() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Normalize Loudness (EBU R128 -16 LUFS)   ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    echo "This will normalize audio in: $dir"
    echo "Output goes to: ${dir}/processed/"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" normalize "$dir"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_trim_silence() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Trim Silence                             ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    echo "This will remove leading and trailing silence from files in: $dir"
    echo "Output goes to: ${dir}/processed/"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" trim-silence "$dir"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_concat() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Concatenate Files                        ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    read -e -p "Enter directory with files to join (or press Enter for current): " dir
    dir="${dir%"${dir##*[![:space:]]}"}"
    dir="${dir:-.}"
    [ ! -d "$dir" ] && { echo "Directory not found!"; sleep 2; return; }
    echo ""
    echo "This will join all audio files in: $dir"
    echo "Files are concatenated in alphabetical order."
    echo "Output: ${dir}/concatenated.mp3"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" concat "$dir"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_split_silence() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Split at Silence                         ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    read -e -p "Enter file path: " file
    file="${file%"${file##*[![:space:]]}"}"
    [ -z "$file" ] && return
    [ ! -f "$file" ] && { echo "File not found!"; sleep 2; return; }
    echo ""
    echo "This will split the file at silence points."
    echo "Output goes to: $(dirname "$file")/$(basename "$file" .*) _split/"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" split-silence "$file"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_clean() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Sanitize Filenames                       ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    echo "This will replace spaces with underscores and remove special characters."
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" clean "$dir"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_rename() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Rename Files with Patterns               ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Available tokens:"
    echo "  {n}     Sequential number (1, 2, 3...)"
    echo "  {orig}  Original filename"
    echo "  {ext}   File extension"
    echo "  {date}  Current date (YYYYMMDD)"
    echo ""
    echo "Example: track_{n}_{orig}"
    echo ""
    read -p "Enter pattern: " pattern
    [ -z "$pattern" ] && return
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    echo "Preview of rename:"
    bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" rename "$dir" --pattern "$pattern" --dry-run
    echo ""
    read -p "Apply this rename? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" rename "$dir" --pattern "$pattern"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_scan() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║      Consolidate from Subfolders                   ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    read -e -p "Enter directory (or press Enter for current): " dir
    dir="${dir%"${dir##*[![:space:]]}"}"
    dir="${dir:-.}"
    [ ! -d "$dir" ] && { echo "Directory not found!"; sleep 2; return; }
    read -p "Output directory name [ALL_AUDIOS]: " output
    output="${output:-ALL_AUDIOS}"
    echo ""
    echo "This will copy all audio files from subfolders to: $output"
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" scan "$dir" -o "$output"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_remove() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Remove Short/Long Files                  ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "  1) Remove short files (below N seconds)"
    echo "  2) Remove long files (above N seconds)"
    echo ""
    read -p "Select option (1-2): " rm_choice
    case "$rm_choice" in
        1) mode="short"; prompt="below" ;;
        2) mode="long"; prompt="above" ;;
        *) return ;;
    esac
    read -p "Threshold in seconds [2]: " threshold
    threshold="${threshold:-2}"
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    echo "Files $prompt $threshold seconds will be moved to trash."
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" remove "$mode" -t "$threshold" "$dir"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_find_dupes() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Find Duplicates (SHA256)                 ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "This will scan files by SHA256 hash and show duplicate groups."
    echo "No files will be deleted."
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" find-dupes "$dir"
    echo ""
    read -p "Press Enter to continue..."
}

menu_dedup() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Remove Duplicates (SHA256)               ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "This will find exact duplicates by SHA256 and move them to trash."
    echo "The first file found is kept; duplicates are removed."
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" dedup "$dir"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

menu_list() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           List Audio Files                         ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    echo "  1) Simple list"
    echo "  2) Table format (with metadata)"
    echo "  3) Tree view"
    echo ""
    read -p "Select format (1-3) [2]: " fmt_choice
    fmt_choice="${fmt_choice:-2}"
    case "$fmt_choice" in
        1) fmt="simple" ;;
        2) fmt="table" ;;
        3) fmt="tree" ;;
        *) fmt="table" ;;
    esac
    echo ""
    bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" list "$dir" --format "$fmt"
    echo ""
    read -p "Press Enter to continue..."
}

menu_stats() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║           Directory Statistics                     ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" stats "$dir"
    echo ""
    read -p "Press Enter to continue..."
}

menu_info() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║          File Metadata                             ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    read -e -p "Enter file path: " file
    file="${file%"${file##*[![:space:]]}"}"
    [ -z "$file" ] && return
    [ ! -f "$file" ] && { echo "File not found!"; sleep 2; return; }
    echo ""
    bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" info "$file"
    echo ""
    read -p "Press Enter to continue..."
}

menu_search() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║        Search & Extract/Delete Files               ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    read -p "Search keyword: " query
    [ -z "$query" ] && return
    echo ""
    echo "  1) List matches"
    echo "  2) Extract matches to folder"
    echo "  3) Delete matches"
    echo ""
    read -p "Select operation (1-3): " op_choice
    case "$op_choice" in
        1) op="list" ;;
        2) op="extract" ;;
        3) op="delete" ;;
        *) return ;;
    esac
    _tui_prompt_path dir "Enter file or directory (or press Enter for current):" || return
    echo ""
    bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" search "$query" --operation "$op" "$dir"
    echo ""
    read -p "Press Enter to continue..."
}

_config_read() {
    local key="$1"
    local file="$AUDIO_TOOLS_CONFIG_FILE"
    if [ -f "$file" ]; then
        grep "^export $key=" "$file" 2>/dev/null | cut -d= -f2- | tr -d '"'
    fi
}

_config_write() {
    local key="$1" value="$2"
    local file="$AUDIO_TOOLS_CONFIG_FILE"
    local dir; dir=$(dirname "$file")
    mkdir -p "$dir" 2>/dev/null
    if [ ! -f "$file" ]; then
        echo "# Audio Tools Configuration" > "$file"
        echo "" >> "$file"
    fi
    if grep -q "^export $key=" "$file" 2>/dev/null; then
        sed -i "s|^export $key=.*|export $key=\"$value\"|" "$file"
    else
        echo "export $key=\"$value\"" >> "$file"
    fi
}

menu_config_edit() {
    while true; do
        clear
        echo "╔════════════════════════════════════════════════════╗"
        echo "║       Edit Configuration                          ║"
        echo "╚════════════════════════════════════════════════════╝"
        echo ""

        local cur_conv=$(_config_read "AUDIO_TOOLS_CONVERTED_DIR")
        cur_conv="${cur_conv:-converted_mp3}"
        local cur_scan=$(_config_read "AUDIO_TOOLS_SCAN_DIR")
        cur_scan="${cur_scan:-ALL_AUDIOS}"
        local cur_force=$(_config_read "AUDIO_TOOLS_FORCE")
        cur_force="${cur_force:-no}"
        local cur_fmt=$(_config_read "AUDIO_TOOLS_FORMAT")
        cur_fmt="${cur_fmt:-mp3}"
        local cur_bit=$(_config_read "AUDIO_TOOLS_BITRATE")
        cur_bit="${cur_bit:-320k}"

        echo "  1) Output directory (convert)   [$cur_conv]"
        echo "  2) Scan directory name           [$cur_scan]"
        echo "  3) Force mode                    [$cur_force]"
        echo "  4) Default format                [$cur_fmt]"
        echo "  5) Default bitrate               [$cur_bit]"
        echo "  0) Back to config menu"
        echo ""
        read -p "Select option (0-5): " opt
        case "$opt" in
            1)
                read -p "Output directory for converted files [$cur_conv]: " val
                val="${val:-$cur_conv}"
                _config_write "AUDIO_TOOLS_CONVERTED_DIR" "$val"
                ;;
            2)
                read -p "Directory name for scan [$cur_scan]: " val
                val="${val:-$cur_scan}"
                _config_write "AUDIO_TOOLS_SCAN_DIR" "$val"
                ;;
            3)
                if [ "$cur_force" = "yes" ]; then
                    _config_write "AUDIO_TOOLS_FORCE" "no"
                else
                    _config_write "AUDIO_TOOLS_FORCE" "yes"
                fi
                ;;
            4)
                read -p "Format (mp3/ogg/aac/flac) [$cur_fmt]: " val
                val="${val:-$cur_fmt}"
                _config_write "AUDIO_TOOLS_FORMAT" "$val"
                ;;
            5)
                read -p "Bitrate (192k/256k/320k) [$cur_bit]: " val
                val="${val:-$cur_bit}"
                _config_write "AUDIO_TOOLS_BITRATE" "$val"
                ;;
            0) return ;;
        esac
    done
}

menu_config() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║          Configuration                            ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "  1) View current settings"
    echo "  2) Edit configuration"
    echo "  3) Reset to defaults"
    echo "  0) Back"
    echo ""
    read -p "Select option (0-3): " cfg_choice
    case "$cfg_choice" in
        1)
            echo ""
            bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" config list
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            menu_config_edit
            ;;
        3)
            read -p "Are you sure? (yes/no): " confirm
            [ "$confirm" = "yes" ] && bash "$AUDIO_TOOLS_BIN_DIR/audio-tools" config reset
            echo ""
            read -p "Press Enter to continue..."
            ;;
    esac
}

export -f show_main_menu run_interactive_menu show_tui_help
export -f menu_convert menu_normalize menu_trim_silence menu_concat menu_split_silence
export -f menu_clean menu_rename menu_scan menu_remove
export -f menu_find_dupes menu_dedup
export -f menu_list menu_stats menu_info menu_search menu_config menu_config_edit
