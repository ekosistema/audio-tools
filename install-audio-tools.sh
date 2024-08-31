#!/bin/bash

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
    # Create bin directory if it doesn't exist
    mkdir -p ~/bin

    # Check if audio_tools.sh exists in the current directory
    if [ ! -f "audio_tools.sh" ]; then
        echo "Error: audio_tools.sh not found in the current directory."
        exit 1
    fi

    # Move audio_tools.sh to ~/bin and rename it
    mv audio_tools.sh ~/bin/audio_tools

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
