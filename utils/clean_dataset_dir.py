    # Process each subdirectory
    successful_cleanups = 0
    skipped_cleanups = 0
    failed_cleanups = []
    
    for i, (subdir_name, subdir_path) in enumerate(subdirectories, 1):
        print(f"\n{'='*80}")
        print(f"Processing subdirectory {i}/{len(subdirectories)}: {subdir_name}")
        print(f"Path: {subdir_path}")
        print(f"{'='*80}")
        
        try:
            # 检查是否只包含 .png 和 .safetensors 文件
            files = [f for f in os.listdir(subdir_path) if os.path.isfile(os.path.join(subdir_path, f))]
            if files:  # 有文件才检查
                allowed_exts = {".png", ".safetensors"}
                if all(Path(f).suffix in allowed_exts for f in files):
                    print(f"✔ Folder already satisfied format，skip: {subdir_name}")
                    skipped_cleanups += 1
                    continue
            
            # Run checkpoint_cleaner.py on this subdirectory
            cmd = [sys.executable, checkpoint_cleaner_path, subdir_path]
            print(f"Running command: {' '.join(cmd)}")
            
            subprocess.run(
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
    print(f"Skipped (already clean): {skipped_cleanups}")
    print(f"Successfully cleaned: {successful_cleanups}")
    print(f"Failed to clean: {len(failed_cleanups)}")
