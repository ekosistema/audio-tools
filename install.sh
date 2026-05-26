#!/bin/bash
# Audio Tools — Installer
# Copyright (c) 2024 CeleroLab.Com — https://celerolab.com
# Usage: bash install.sh [--version VERSION] [--update]
#   --version VERSION   Install specific version (default: latest from VERSION file)
#   --update            Update existing installation (skip if same version)

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/audio-tools"
BIN_DIR="$HOME/.local/bin"
EXECUTABLE_NAME="audio-tools"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_shell_config() {
    local shell_name
    shell_name=$(basename "${SHELL:-bash}")
    case "$shell_name" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc"  ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "" ;;
    esac
}

check_windows() {
    if [[ -n "${WSLENV:-}" ]]; then
        log_info "Detected Windows Subsystem for Linux (WSL)."
        log_info "Continuing installation inside WSL..."
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        log_error "Windows (without WSL) is not supported directly."
        log_info "Install WSL (https://learn.microsoft.com/en-us/windows/wsl/install)"
        log_info "then run this installer from inside WSL."
        exit 1
    fi
}

install_dependencies() {
    log_info "Checking dependencies..."
    if command_exists ffmpeg && command_exists ffprobe; then
        log_info "ffmpeg and ffprobe are already installed."
        return 0
    fi
    log_info "Installing ffmpeg..."
    if command_exists apt-get; then
        sudo apt-get update -qq && sudo apt-get install -y -qq ffmpeg
    elif command_exists brew; then
        brew install ffmpeg
    elif command_exists dnf; then
        sudo dnf install -y ffmpeg
    elif command_exists yum; then
        sudo yum install -y ffmpeg
    elif command_exists pacman; then
        sudo pacman -S --noconfirm ffmpeg
    else
        log_error "Could not identify package manager. Install ffmpeg manually."
        exit 1
    fi
}

read_local_version() {
    local vfile="$INSTALL_DIR/VERSION"
    if [ -f "$vfile" ]; then
        cat "$vfile"
    else
        echo ""
    fi
}

install_files() {
    local src_dir="$1"
    log_info "Installing files to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"

    cp -r "$src_dir/bin" "$src_dir/lib" "$src_dir/VERSION" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/bin/audio-tools"

    ln -sf "$INSTALL_DIR/bin/audio-tools" "$BIN_DIR/$EXECUTABLE_NAME"
    log_info "Created symlink at $BIN_DIR/$EXECUTABLE_NAME"
}

update_path() {
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        local config_file
        config_file=$(detect_shell_config)
        if [ -n "$config_file" ]; then
            if ! grep -q "$BIN_DIR" "$config_file" 2>/dev/null; then
                echo "" >> "$config_file"
                echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$config_file"
                log_info "Added $BIN_DIR to PATH in $config_file"
                log_info "Run 'source $config_file' or restart your terminal."
            else
                log_info "$BIN_DIR is already configured in $config_file"
            fi
        else
            log_info "Could not detect shell config. Add $BIN_DIR to your PATH manually."
        fi
    fi
}

install_completion() {
    local config_file
    config_file=$(detect_shell_config)
    if [ -z "$config_file" ]; then
        return 0
    fi
    if grep -q "audio-tools completion" "$config_file" 2>/dev/null; then
        return 0
    fi
    case "$(basename "${SHELL:-bash}")" in
        bash)
            echo "" >> "$config_file"
            echo "# audio-tools shell completion" >> "$config_file"
            echo "source <($BIN_DIR/audio-tools completion bash) 2>/dev/null" >> "$config_file"
            log_info "Installed bash completion in $config_file"
            ;;
        zsh)
            echo "" >> "$config_file"
            echo "# audio-tools shell completion" >> "$config_file"
            echo "source <($BIN_DIR/audio-tools completion zsh) 2>/dev/null" >> "$config_file"
            log_info "Installed zsh completion in $config_file"
            ;;
    esac
}

main() {
    local requested_version=""
    local update_mode=false

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) requested_version="$2"; shift ;;
            --update)  update_mode=true ;;
            --help|-h)
                echo "Usage: bash install.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --version VERSION   Install specific version (default: local VERSION file)"
                echo "  --update            Update existing installation (skip if same version)"
                echo "  --help, -h          Show this help"
                exit 0
                ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    check_windows
    install_dependencies

    local src_dir
    src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

    local install_version
    if [ -n "$requested_version" ]; then
        install_version="$requested_version"
    else
        install_version=$(cat "$src_dir/VERSION" 2>/dev/null || echo "unknown")
    fi

    # Update check
    if [ "$update_mode" = true ]; then
        local local_version
        local_version=$(read_local_version)
        if [ "$local_version" = "$install_version" ]; then
            log_info "Version $install_version is already installed. Nothing to do."
            exit 0
        fi
        log_info "Updating from $local_version to $install_version..."
    fi

    install_files "$src_dir"
    update_path
    install_completion

    log_info "Installation completed successfully!"
    log_info "Run '$EXECUTABLE_NAME' to start."
    log_info "Version: $install_version"
}

main "$@"
