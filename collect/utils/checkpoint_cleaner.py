import os
import shutil
import sys


def clean_target_dir_except_png(directory):
    """
    Clean target directory: delete all files except .png files.
    """
    print("Step 1: Cleaning target directory (keeping only .png files)...")
    
    for item in os.listdir(directory):
        item_path = os.path.join(directory, item)
        
        if os.path.isfile(item_path):
            # Keep .png files, delete everything else
            if not item.endswith(".png"):
                os.remove(item_path)
                print(f"Deleted file: {item_path}")
        elif os.path.isdir(item_path):
            # Keep directories for now (they will be processed later)
            continue


def process_checkpoints_and_cleanup(target_dir):
    """
    Find the checkpoint with maximum number, keep the latest 120 checkpoints,
    delete the rest, then extract .safetensors files from remaining checkpoints.
    """
    print("Step 2: Processing checkpoint directories...")
    
    checkpoint_dirs = []
    
    # Find all checkpoint directories and extract their numbers
    for dir_name in os.listdir(target_dir):
        dir_path = os.path.join(target_dir, dir_name)
        
        if os.path.isdir(dir_path) and dir_name.startswith("checkpoint-"):
            try:
                checkpoint_number = int(dir_name.split("-")[1])
                checkpoint_dirs.append((checkpoint_number, dir_name, dir_path))
            except (IndexError, ValueError) as e:
                print(f"Error parsing checkpoint number from {dir_name}: {e}")
                continue
    
    if not checkpoint_dirs:
        print("No checkpoint directories found.")
        return
    
    # Sort by checkpoint number
    checkpoint_dirs.sort(key=lambda x: x[0])
    
    max_checkpoint_num = checkpoint_dirs[-1][0]
    print(f"Maximum checkpoint number found: {max_checkpoint_num}")
    
    # Calculate the minimum checkpoint number to keep (keep latest 100)
    min_checkpoint_to_keep = max_checkpoint_num - 99  # Keep 100 checkpoints including the max
    print(f"Will keep checkpoints from {min_checkpoint_to_keep} to {max_checkpoint_num}")
    
    # Delete checkpoints that are below the threshold
    deleted_count = 0
    kept_checkpoints = []
    
    for checkpoint_num, dir_name, dir_path in checkpoint_dirs:
        if checkpoint_num < min_checkpoint_to_keep:
            try:
                shutil.rmtree(dir_path)
                print(f"Deleted checkpoint directory: {dir_path}")
                deleted_count += 1
            except Exception as e:
                print(f"Error deleting {dir_path}: {e}")
        else:
            kept_checkpoints.append((checkpoint_num, dir_name, dir_path))
    
    print(f"Deleted {deleted_count} checkpoint directories")
    print(f"Kept {len(kept_checkpoints)} checkpoint directories")
    
    return kept_checkpoints


def extract_safetensors_from_checkpoints(target_dir, kept_checkpoints):
    """
    Extract .safetensors files from checkpoint directories and move them to target_dir.
    """
    print("Step 3: Extracting .safetensors files from checkpoint directories...")
    
    for checkpoint_num, dir_name, dir_path in kept_checkpoints:
        print(f"Processing checkpoint: {dir_name}")
        
        # Find .safetensors files in the checkpoint directory
        safetensors_files = []
        for item in os.listdir(dir_path):
            item_path = os.path.join(dir_path, item)
            if os.path.isfile(item_path) and item.endswith(".safetensors"):
                safetensors_files.append((item, item_path))
        
        # Move .safetensors files to target directory
        for filename, file_path in safetensors_files:
            # Create a unique name to avoid conflicts
            new_filename = f"checkpoint-{checkpoint_num}_{filename}"
            new_path = os.path.join(target_dir, new_filename)
            
            try:
                shutil.move(file_path, new_path)
                print(f"Moved {file_path} to {new_path}")
            except Exception as e:
                print(f"Error moving {file_path}: {e}")
        
        # Delete the checkpoint directory after extracting .safetensors files
        try:
            shutil.rmtree(dir_path)
            print(f"Deleted checkpoint directory: {dir_path}")
        except Exception as e:
            print(f"Error deleting checkpoint directory {dir_path}: {e}")


def final_cleanup(target_dir):
    """
    Final cleanup: keep only .safetensors and train_loss.png files.
    """
    print("Step 4: Final cleanup (keeping only .safetensors and train_loss.png)...")
    
    for item in os.listdir(target_dir):
        item_path = os.path.join(target_dir, item)
        
        if os.path.isfile(item_path):
            # Keep .safetensors files and training_loss.png
            if not (item.endswith(".safetensors") or item.endswith(".png")):
                try:
                    os.remove(item_path)
                    print(f"Deleted file: {item_path}")
                except Exception as e:
                    print(f"Error deleting {item_path}: {e}")
        elif os.path.isdir(item_path):
            # Delete any remaining directories
            try:
                shutil.rmtree(item_path)
                print(f"Deleted directory: {item_path}")
            except Exception as e:
                print(f"Error deleting directory {item_path}: {e}")


if __name__ == "__main__":
    # Get target directory from command line arguments
    if len(sys.argv) != 2:
        print("Usage: python script.py <target_directory_path>")
        print("Example: python script.py /path/to/your/model/saves")
        exit(1)
    
    target_dir = sys.argv[1]
    
    # Verify that the target directory exists
    if not os.path.exists(target_dir):
        print(f"Error: Directory '{target_dir}' does not exist")
        exit(1)
    
    if not os.path.isdir(target_dir):
        print(f"Error: '{target_dir}' is not a directory")
        exit(1)
    
    print(f"Processing target directory: {target_dir}")
    print("="*60)
    
    try:
        # Step 1: Clean target directory (keep only .png files)
        clean_target_dir_except_png(target_dir)
        
        # Step 2: Process checkpoints and get the list of kept checkpoints
        kept_checkpoints = process_checkpoints_and_cleanup(target_dir)
        
        # Step 3: Extract .safetensors files from kept checkpoints
        if kept_checkpoints:
            extract_safetensors_from_checkpoints(target_dir, kept_checkpoints)
        
        # Step 4: Final cleanup
        final_cleanup(target_dir)
        
        print("="*60)
        print("Processing completed successfully!")
        
        # Show final contents
        print(f"\nFinal contents of {target_dir}:")
        for item in sorted(os.listdir(target_dir)):
            print(f"  - {item}")
            
    except Exception as e:
        print(f"An error occurred during processing: {e}")
        exit(1)
