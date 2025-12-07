#!/bin/bash

# ==============================================================================
# Audio Tools - Installer
#
# Description: Automated installation script for Audio Tools.
# Author: CeleroLab.Com
# Copyright: (c) 2024 CeleroLab.Com
# License: MIT
# ==============================================================================

INSTALL_DIR="$HOME/.local/share/audio-tools"
BIN_DIR="$HOME/.local/bin"
EXECUTABLE_NAME="audio-tools"

# Color helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_shell_config() {
    local shell_name
    shell_name=$(basename "$SHELL")
    case "$shell_name" in
        zsh) echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        *) echo "" ;;
    esac
}

install_dependencies() {
    log_info "Checking dependencies..."
    if command_exists ffmpeg; then
        log_info "FFmpeg is already installed."
    else
        log_info "Installing FFmpeg..."
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y ffmpeg
        elif command_exists brew; then
            brew install ffmpeg
        elif command_exists yum; then
            sudo yum install -y ffmpeg
        elif command_exists dnf; then
            sudo dnf install -y ffmpeg
        elif command_exists pacman; then
            sudo pacman -S ffmpeg
        else
            log_error "Could not identify package manager. Please install ffmpeg manually."
            exit 1
        fi
    fi
}

install_files() {
    log_info "Installing files to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"

    # Copy files
    cp -r bin lib "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/bin/audio-tools"

    # Create symlink
    ln -sf "$INSTALL_DIR/bin/audio-tools" "$BIN_DIR/$EXECUTABLE_NAME"
    log_info "Created symlink at $BIN_DIR/$EXECUTABLE_NAME"
}

update_path() {
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        local config_file
        config_file=$(detect_shell_config)
        
        if [ -n "$config_file" ]; then
            if ! grep -q "$BIN_DIR" "$config_file"; then
                echo "" >> "$config_file"
                echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$config_file"
                log_info "Added $BIN_DIR to PATH in $config_file"
                log_info "Please run 'source $config_file' or restart your terminal."
            else
                log_info "$BIN_DIR is already configured in $config_file"
            fi
        else
            log_info "Could not detect shell config. Please add $BIN_DIR to your PATH manually."
        fi
    fi
}

main() {
    install_dependencies
    install_files
    update_path
    log_info "Installation completed successfully!"
    log_info "Run '$EXECUTABLE_NAME' to start."
}

main
