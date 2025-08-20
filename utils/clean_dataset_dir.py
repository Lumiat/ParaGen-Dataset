#!/usr/bin/env python3
"""
Script to clean all subdirectories in a specific dataset directory using checkpoint_cleaner.py
Usage: python clean_dataset_dir.py --type <type> --dataset <dataset>
Example: python clean_dataset_dir.py --type common_sense_reasoning --dataset ARC-c
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path


def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(
        description="Clean all subdirectories in a dataset directory using checkpoint_cleaner.py",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python clean_dataset_dir.py --type common_sense_reasoning --dataset ARC-c
  python clean_dataset_dir.py --type sentiment_analysis --dataset imdb
        """
    )
    
    parser.add_argument(
        "--type", 
        required=True, 
        help="Type of the dataset (e.g., common_sense_reasoning)"
    )
    
    parser.add_argument(
        "--dataset", 
        required=True, 
        help="Name of the dataset (e.g., ARC-c)"
    )
    
    # Parse arguments
    args = parser.parse_args()
    
    # Define base path and target directory
    base_path = "/research-intern05/xjy/ParaGen-Dataset/saves"
    target_directory = os.path.join(base_path, args.type, args.dataset)
    
    print(f"Target directory: {target_directory}")
    print("="*80)
    
    # Check if the target directory exists
    if not os.path.exists(target_directory):
        print(f"Error: Directory '{target_directory}' does not exist")
        sys.exit(1)
    
    if not os.path.isdir(target_directory):
        print(f"Error: '{target_directory}' is not a directory")
        sys.exit(1)
    
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    checkpoint_cleaner_path = os.path.join(script_dir, "checkpoint_cleaner.py")
    
    # Check if checkpoint_cleaner.py exists
    if not os.path.exists(checkpoint_cleaner_path):
        print(f"Error: checkpoint_cleaner.py not found at: {checkpoint_cleaner_path}")
        print("Make sure checkpoint_cleaner.py is in the same directory as this script")
        sys.exit(1)
    
    # Get all subdirectories in the target directory
    subdirectories = []
    try:
        for item in os.listdir(target_directory):
            item_path = os.path.join(target_directory, item)
            if os.path.isdir(item_path):
                subdirectories.append((item, item_path))
    except Exception as e:
        print(f"Error reading directory '{target_directory}': {e}")
        sys.exit(1)
    
    if not subdirectories:
        print(f"No subdirectories found in '{target_directory}'")
        sys.exit(0)
    
    print(f"Found {len(subdirectories)} subdirectories to clean:")
    for name, path in subdirectories:
        print(f"  - {name}")
    print()
    
    # Ask for confirmation
    try:
        response = input(f"Do you want to proceed with cleaning all {len(subdirectories)} subdirectories? [y/N]: ")
        if response.lower() not in ['y', 'yes']:
            print("Operation cancelled.")
            sys.exit(0)
    except KeyboardInterrupt:
        print("\nOperation cancelled.")
        sys.exit(0)
    
    # Process each subdirectory
    successful_cleanups = 0
    failed_cleanups = []
    
    for i, (subdir_name, subdir_path) in enumerate(subdirectories, 1):
        print(f"\n{'='*80}")
        print(f"Processing subdirectory {i}/{len(subdirectories)}: {subdir_name}")
        print(f"Path: {subdir_path}")
        print(f"{'='*80}")
        
        try:
            # Run checkpoint_cleaner.py on this subdirectory
            cmd = [sys.executable, checkpoint_cleaner_path, subdir_path]
            print(f"Running command: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                check=True,
                capture_output=False,  # Show output in real-time
                text=True
            )
            
            print(f"✓ Successfully cleaned: {subdir_name}")
            successful_cleanups += 1
            
        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to clean: {subdir_name}")
            print(f"  Error: subprocess returned non-zero exit status {e.returncode}")
            failed_cleanups.append((subdir_name, f"Exit code: {e.returncode}"))
            
        except Exception as e:
            print(f"✗ Failed to clean: {subdir_name}")
            print(f"  Error: {e}")
            failed_cleanups.append((subdir_name, str(e)))
    
    # Print summary
    print(f"\n{'='*80}")
    print("CLEANUP SUMMARY")
    print(f"{'='*80}")
    print(f"Total subdirectories: {len(subdirectories)}")
    print(f"Successfully cleaned: {successful_cleanups}")
    print(f"Failed to clean: {len(failed_cleanups)}")
    
    if failed_cleanups:
        print(f"\nFailed subdirectories:")
        for subdir_name, error in failed_cleanups:
            print(f"  - {subdir_name}: {error}")
    
    if successful_cleanups == len(subdirectories):
        print(f"\n🎉 All subdirectories cleaned successfully!")
    elif successful_cleanups > 0:
        print(f"\n⚠️  Partial success: {successful_cleanups}/{len(subdirectories)} subdirectories cleaned")
    else:
        print(f"\n❌ No subdirectories were cleaned successfully")
        sys.exit(1)


if __name__ == "__main__":
    main()
