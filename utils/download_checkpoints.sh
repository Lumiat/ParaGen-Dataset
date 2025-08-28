#!/bin/bash

# ================================================
# Script Name: compress_subdirs.sh
# Description: This script takes a directory path
#              as an argument, and compresses each
#              subdirectory under that path into a
#              .zip file with the same name.
#              The generated .zip files are stored
#              in the given directory itself.
# Usage: ./compress_subdirs.sh /path/to/target_dir
# ================================================

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Error: No directory path provided."
    echo "Usage: $0 /path/to/target_dir"
    exit 1
fi

# Assign input directory to a variable
TARGET_DIR="$1"

# Check if the path exists and is a directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: $TARGET_DIR is not a valid directory."
    exit 1
fi

# Change to target directory
cd "$TARGET_DIR" || exit 1

# Loop through all subdirectories
for dir in */; do
    # Remove trailing slash from directory name
    dir_name=$(basename "$dir")
    
    # Create .zip file with the same name as subdirectory
    zip -r "${dir_name}.zip" "$dir_name"
done

echo "All subdirectories in $TARGET_DIR have been compressed into .zip files."
