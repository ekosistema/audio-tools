#!/bin/bash

# Function to check if a file is an audio file
is_audio_file() {
    local file="$1"
    local ext="${file##*.}"
    case "${ext,,}" in
        mp3|wav|ogg|flac|aac|wma|m4a) return 0 ;;
        *) return 1 ;;
    esac
}

# Request the path of the folder to scan
read -p "Please enter the path of the folder to scan: " source_folder

# Check if the folder exists
if [ ! -d "$source_folder" ]; then
    echo "Error: The specified folder does not exist."
    exit 1
fi

# Create the destination folder
destination_folder="$source_folder/ALL_AUDIOS"
mkdir -p "$destination_folder"

# Function to copy audio files
copy_audio_files() {
    local source="$1"
    find "$source" -type f | while read -r file; do
        if is_audio_file "$file"; then
            base_name=$(basename "$file")
            destination="$destination_folder/$base_name"
            counter=1
            while [ -e "$destination" ]; do
                name="${base_name%.*}"
                extension="${base_name##*.}"
                destination="$destination_folder/${name}_${counter}.${extension}"
                ((counter++))
            done
            cp "$file" "$destination"
            echo "Copied: $file -> $destination"
        fi
    done
}

# Execute the main function
copy_audio_files "$source_folder"

echo "Process completed. All audio files have been copied to the ALL_AUDIOS folder."