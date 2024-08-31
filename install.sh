#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    echo "Checking and installing dependencies for the Audio Tools Scripts..."

    # Check if ffmpeg is installed
    if command_exists ffmpeg; then
        echo "FFmpeg is already installed."
    else
        echo "FFmpeg is not installed. Attempting to install..."
        
        # Check the package manager and install ffmpeg
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y ffmpeg sed
        elif command_exists yum; then
            sudo yum install -y ffmpeg sed
        elif command_exists brew; then
            brew install ffmpeg sed
        else
            echo "Unable to install FFmpeg. Please install it manually."
            exit 1
        fi
        
        # Verify installation
        if command_exists ffmpeg; then
            echo "FFmpeg has been successfully installed."
        else
            echo "Failed to install FFmpeg. Please install it manually."
            exit 1
        fi
    fi

    echo "All dependencies are installed."
}

# Function to detect the current shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Function to add directory to PATH in the appropriate shell config file
add_to_path() {
    local shell_config
    case $1 in
        zsh)
            shell_config="$HOME/.zshrc"
            ;;
        bash)
            shell_config="$HOME/.bashrc"
            ;;
        *)
            echo "Unsupported shell. Please add ~/bin to your PATH manually."
            return 1
            ;;
    esac

    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$shell_config"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_config"
        echo "Added ~/bin to PATH in $shell_config"
    else
        echo "~/bin is already in PATH in $shell_config"
    fi
}

# Main installation process
main() {
    # Install dependencies
    install_dependencies

    # Create bin directory if it doesn't exist
    mkdir -p ~/bin

    # Download audio_tools.sh from GitHub and move it to ~/bin
    echo "Downloading audio_tools script..."
    curl -s https://raw.githubusercontent.com/ekosistema/audio-tools/main/audio_tools.sh > ~/bin/audio_tools

    # Make it executable
    chmod +x ~/bin/audio_tools

    # Detect shell and add ~/bin to PATH
    local shell_type=$(detect_shell)
    add_to_path "$shell_type"

    echo "Installation completed. Please restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc' depending on your shell."
    echo "You can now use the 'audio_tools' command from anywhere in your system."
}

# Run the main function
main
