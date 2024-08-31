#!/bin/bash

# Ask for the directory path
read -p "Enter the folder path: " directory

# Check if the directory exists
if [ ! -d "$directory" ]; then
    echo "The directory does not exist."
    exit 1
fi

# Loop through all files in the directory
for file in "$directory"/*; do
    # Check if it's a file (not a directory)
    if [ -f "$file" ]; then
        # Get the directory and filename separately
        dir=$(dirname "$file")
        filename=$(basename "$file")
        
        # Remove non-standard characters, replace spaces with underscores
        newname=$(echo "$filename" | sed -e 's/[^A-Za-z0-9._-]//g' -e 's/ /_/g')
        
        # Rename the file if the name has changed
        if [ "$filename" != "$newname" ]; then
            mv "$file" "$dir/$newname"
            echo "Renamed: $filename -> $newname"
        fi
    fi
done

echo "Process completed."
