#!/bin/bash

# Function to get folder path from user
get_folder_path() {
    local prompt="$1"
    local default_path="$(pwd)"
    read -p "${prompt} (press Enter for current folder [$default_path]): " user_input
    echo "${user_input:-$default_path}"
}

# Function to move a file to trash or to_delete folder
move_to_trash() {
    local file="$1"
    local root_folder="$2"
    local to_delete_folder="${root_folder}/to_delete"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if mv "$file" ~/.Trash/; then
            return 0
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v gio &> /dev/null; then
            # Linux with gio (GNOME)
            if gio trash "$file"; then
                return 0
            fi
        elif command -v trash-put &> /dev/null; then
            # Linux with trash-cli
            if trash-put "$file"; then
                return 0
            fi
        else
            # Fallback: create a .Trash folder in user's home if it doesn't exist
            mkdir -p ~/.Trash
            if mv "$file" ~/.Trash/; then
                return 0
            fi
        fi
    fi

    # If all above methods fail, move to to_delete folder
    mkdir -p "$to_delete_folder"
    if mv "$file" "$to_delete_folder/"; then
        echo "Failed to move to trash. File moved to $to_delete_folder instead."
        return 2
    else
        echo "Failed to move file to trash or $to_delete_folder. File remains in its original location."
        return 1
    fi
}

# Function to convert files to MP3
convert_to_mp3() {
    local source_folder=$(get_folder_path "Enter the path to the folder containing the audio files")

    if [ ! -d "$source_folder" ]; then
        echo "The specified folder does not exist."
        return
    fi

    output_folder="${source_folder}/converted_mp3"
    mkdir -p "$output_folder"

    find "$source_folder" -type f \( -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) | while read -r file; do
        echo "Converting: $file"
        output_file="${output_folder}/$(basename "${file%.*}").mp3"
        ffmpeg -i "$file" -acodec libmp3lame -b:a 320k -ar 44100 -ac 2 "$output_file"
    done

    echo "Conversion completed. MP3 files are located in: $output_folder"
}

# Function to remove short audio files
remove_short_audios() {
    local audio_folder=$(get_folder_path "Enter the path to the folder containing the audio files")

    if [ ! -d "$audio_folder" ]; then
        echo "The specified folder does not exist or is not accessible."
        return
    fi

    read -p "Enter the maximum duration in seconds for files to be deleted: " max_duration

    if ! [[ "$max_duration" =~ ^[0-9]+$ ]]; then
        echo "Please enter a valid number for the duration."
        return
    fi

    echo "WARNING: You are about to delete short audio files. This action is potentially destructive."
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        echo "Operation cancelled. No files were deleted."
        return
    fi

    trash_count=0
    to_delete_count=0
    fail_count=0

    find "$audio_folder" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) -print0 | 
    while IFS= read -r -d '' file; do
        duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
        duration=${duration%.*}
        
        if [ "$duration" -lt "$max_duration" ]; then
            echo "Processing: $file (duration: $duration seconds)"
            result=$(move_to_trash "$file" "$audio_folder")
            case $? in
                0) ((trash_count++));;
                2) ((to_delete_count++));;
                1) ((fail_count++));;
            esac
        fi
    done

    echo "Operation completed."
    echo "$trash_count files moved to trash."
    [ $to_delete_count -gt 0 ] && echo "$to_delete_count files moved to ${audio_folder}/to_delete folder."
    [ $fail_count -gt 0 ] && echo "$fail_count files could not be moved."
}

# Function to scan and copy audio files from subfolders
scan_audios_subfolders() {
    local source_folder=$(get_folder_path "Enter the path of the folder to scan")

    if [ ! -d "$source_folder" ]; then
        echo "Error: The specified folder does not exist."
        return
    fi

    destination_folder="$source_folder/ALL_AUDIOS"
    mkdir -p "$destination_folder"

    find "$source_folder" -type f | while read -r file; do
        if [[ "${file,,}" =~ \.(mp3|wav|ogg|flac|aac|wma|m4a)$ ]]; then
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

    echo "Process completed. All audio files have been copied to the ALL_AUDIOS folder."
}

# Function to clean filenames
clean_filenames() {
    local directory=$(get_folder_path "Enter the folder path")

    if [ ! -d "$directory" ]; then
        echo "The directory does not exist."
        return
    fi

    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            dir=$(dirname "$file")
            filename=$(basename "$file")
            
            newname=$(echo "$filename" | sed -e 's/[^A-Za-z0-9._-]//g' -e 's/ /_/g')
            
            if [ "$filename" != "$newname" ]; then
                mv "$file" "$dir/$newname"
                echo "Renamed: $filename -> $newname"
            fi
        fi
    done

    echo "Process completed."
}

# Function to remove long audio files
remove_long_audios() {
    local audio_folder=$(get_folder_path "Enter the path to the folder containing the audio files")

    if [ ! -d "$audio_folder" ]; then
        echo "The specified folder does not exist or is not accessible."
        return
    fi

    read -p "Enter the maximum duration in seconds for files to keep: " max_duration

    if ! [[ "$max_duration" =~ ^[0-9]+$ ]]; then
        echo "Please enter a valid number for the duration."
        return
    fi

    echo "WARNING: You are about to delete long audio files. This action is potentially destructive."
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        echo "Operation cancelled. No files were deleted."
        return
    fi

    trash_count=0
    to_delete_count=0
    fail_count=0

    find "$audio_folder" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) -print0 | 
    while IFS= read -r -d '' file; do
        duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
        duration=${duration%.*}
        
        if [ "$duration" -gt "$max_duration" ]; then
            echo "Processing: $file (duration: $duration seconds)"
            result=$(move_to_trash "$file" "$audio_folder")
            case $? in
                0) ((trash_count++));;
                2) ((to_delete_count++));;
                1) ((fail_count++));;
            esac
        fi
    done

    echo "Operation completed."
    echo "$trash_count files moved to trash."
    [ $to_delete_count -gt 0 ] && echo "$to_delete_count files moved to ${audio_folder}/to_delete folder."
    [ $fail_count -gt 0 ] && echo "$fail_count files could not be moved."
}

# Function to search and process audio files
search_and_process_audios() {
    local initial_folder=$(get_folder_path "Enter the path of the folder to search")

    if [ ! -d "$initial_folder" ]; then
        echo "Error: The folder '$initial_folder' does not exist."
        return 1
    fi

    read -p "Enter the text string to search for: " search_string

    echo "Searching for audio files containing '$search_string' in '$initial_folder'..."

    found_files=$(find "$initial_folder" -type f \( -iname "*${search_string}*.mp3" -o -iname "*${search_string}*.wav" -o -iname "*${search_string}*.ogg" -o -iname "*${search_string}*.flac" \) )

    if [ -z "$found_files" ]; then
        echo "No audio files containing '$search_string' were found."
        return 0
    fi

    file_count=$(echo "$found_files" | wc -l)
    echo "$file_count files found."

    while true; do
        read -p "What do you want to do? (d)elete or (e)xtract: " action
        case $action in
            [Dd]* ) 
                echo "WARNING: You are about to move $file_count files to the trash. This action is potentially destructive."
                read -p "Are you sure you want to proceed? (yes/no): " confirm
                if [[ $confirm == "yes" ]]; then
                    echo "Moving files to trash..."
                    trash_count=0
                    to_delete_count=0
                    fail_count=0
                    echo "$found_files" | while read -r file; do
                        result=$(move_to_trash "$file" "$initial_folder")
                        case $? in
                            0) ((trash_count++));;
                            2) ((to_delete_count++));;
                            1) ((fail_count++));;
                        esac
                    done
                    echo "Operation completed."
                    echo "$trash_count files moved to trash."
                    [ $to_delete_count -gt 0 ] && echo "$to_delete_count files moved to ${initial_folder}/to_delete folder."
                    [ $fail_count -gt 0 ] && echo "$fail_count files could not be moved."
                else
                    echo "Operation cancelled. No files were moved."
                fi
                break
                ;;
            [Ee]* )
                destination_folder="${initial_folder}/${search_string}"
                mkdir -p "$destination_folder"
                echo "Copying $file_count files to $destination_folder..."
                echo "$found_files" | while read -r file; do
                    cp -v "$file" "$destination_folder/"
                done
                echo "Operation completed. $file_count files copied to $destination_folder"
                break
                ;;
            * ) echo "Please answer d for delete or e for extract.";;
        esac
    done
}

# Main function
main() {
    while true; do
        echo "
Select an option:
1. Convert files to MP3
2. Remove short audio files
3. Scan and copy audio files from subfolders
4. Clean filenames
5. Remove long audio files
6. Search and process audio files
7. Exit
"
        read -p "Enter the number of the desired option: " choice

        case $choice in
            1) convert_to_mp3 ;;
            2) remove_short_audios ;;
            3) scan_audios_subfolders ;;
            4) clean_filenames ;;
            5) remove_long_audios ;;
            6) search_and_process_audios ;;
            7) echo "Exiting the program."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac

        read -p "Do you want to perform another operation? (y/n): " continue
        if [[ ${continue,,} != "y" ]]; then
            echo "Exiting the program."
            break
        fi
    done
}

# Run the main function
main
