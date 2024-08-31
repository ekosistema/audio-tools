#!/bin/bash

echo "Checking and installing dependencies for the Audio Tools Scripts..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

echo "All dependencies are installed. You can now run the Audio Tools Scripts."
