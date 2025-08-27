import os

def rename_files(path, target, sub):
    if not os.path.exists(path):
        print(f"Path does not exist: {path}")
        return

    for root, dirs, files in os.walk(path):
        for filename in files:
            if target in filename:
                old_path = os.path.join(root, filename)
                new_filename = filename.replace(target, sub)
                new_path = os.path.join(root, new_filename)
                try:
                    os.rename(old_path, new_path)
                    print(f"rename: {old_path} -> {new_path}")
                except Exception as e:
                    print(f"rename failed: {old_path}, error: {e}")

if __name__ == "__main__":
    path = input("Dir Path: <path>: ").strip()
    target = input("Target String <target>: ").strip()
    sub = input("Substitution String <sub>: ").strip()
    rename_files(path, target, sub)
