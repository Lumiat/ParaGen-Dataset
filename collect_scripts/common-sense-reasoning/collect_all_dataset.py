#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import glob
import shutil
import re

# ==============================
# Dataset mapping
# ==============================
DATASET_MAPPING = {
    "arcc": "ARC-c",
    "arce": "ARC-e", 
    "obqa": "OBQA",
    "piqa": "PIQA",
    "hellaswag": "HellaSwag",
    "winogrande": "WinoGrande",
    "boolq": "BoolQ",
}

RANKS = [2, 4, 8, 16, 64]
MODELS = ["bert", "gpt2", "llama-7b", "mistral-7b", "qwen2.5-0.5b", "gemma-3-4b"]
TRAIN_SCRIPT_REL = "../../../utils/train_with_rank.sh"


# ==============================
# Utility functions
# ==============================

def extract_output_dir(yaml_file):
    """Extract output_dir field from yaml config"""
    with open(yaml_file, "r") as f:
        for line in f:
            if "output_dir:" in line:
                return line.split("output_dir:")[-1].strip().strip('"').strip("'")
    return None


def get_resume_checkpoint_path(yaml_file):
    """Extract resume_from_checkpoint field from yaml config"""
    with open(yaml_file, "r") as f:
        for line in f:
            if "resume_from_checkpoint:" in line:
                return line.split("resume_from_checkpoint:")[-1].strip().strip('"').strip("'")
    return ""


def replace_rank_in_path(path, new_rank):
    """
    Replace the rank number in lora-rank_X pattern with new_rank
    Uses regex to precisely match the rank pattern
    """
    if not path:
        return path
    
    # Use regex to match lora-rank_X pattern and replace only the rank number
    pattern = r'(lora-rank_)(\d+)'
    replacement = rf'\g<1>{new_rank}'
    new_path = re.sub(pattern, replacement, path)
    
    print(f"Path replacement: {path} -> {new_path}")
    return new_path


def update_save_steps(json_file):
    """Update trainer_state.json save_steps=1"""
    if os.path.isfile(json_file):
        print(f"Updating save_steps to 1 in: {json_file}")
        try:
            with open(json_file, "r") as f:
                data = json.load(f)
            data["save_steps"] = 1
            with open(json_file, "w") as f:
                json.dump(data, f, indent=2)
            print("Successfully updated save_steps to 1")
        except Exception as e:
            print(f"Error updating save_steps: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"Warning: trainer_state.json not found at: {json_file}")


def cleanup_pretrain_folders(dataset_folder):
    """Remove pretrain dirs under save directory"""
    pretrain_save_dir = f"/research-intern05/xjy/ParaGen-Dataset/saves/common_sense_reasoning/{dataset_folder}"
    print("-----------------------------------------------")
    print(f"Cleaning up pretrain folders in: {pretrain_save_dir}")
    print("-----------------------------------------------")

    if os.path.isdir(pretrain_save_dir):
        pretrain_dirs = glob.glob(os.path.join(pretrain_save_dir, "*pretrain"))
        if pretrain_dirs:
            print("Found pretrain directories to remove:")
            for d in pretrain_dirs:
                print(d)
                try:
                    shutil.rmtree(d)
                    print(f"Successfully removed: {d}")
                except Exception as e:
                    print(f"Error: Failed to remove {d}: {e}")
        else:
            print(f"No pretrain directories found to remove in: {pretrain_save_dir}")
    else:
        print(f"Warning: Save directory does not exist: {pretrain_save_dir}")


def run_bash(cmd_list):
    """Run bash command, returns success bool"""
    try:
        subprocess.run(cmd_list, check=True)
        return True
    except subprocess.CalledProcessError:
        return False


# ==============================
# Main
# ==============================
def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <dataset>")
        print(f"Example: {sys.argv[0]} arcc")
        sys.exit(1)

    dataset = sys.argv[1]
    dataset_folder = DATASET_MAPPING.get(dataset)
    if dataset_folder is None:
        print(f"Error: Unknown dataset '{dataset}'. Supported datasets: {list(DATASET_MAPPING.keys())}")
        sys.exit(1)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_dir = os.path.join(script_dir, dataset_folder)

    if not os.path.isdir(config_dir):
        print(f"Error: Dataset folder not found: {config_dir}")
        sys.exit(1)

    print(f"Changing working directory to: {config_dir}")
    os.chdir(config_dir)

    if os.getcwd() != config_dir:
        print(f"Error: Failed to change working directory to {config_dir}")
        sys.exit(1)

    print(f"Current working directory: {os.getcwd()}")
    print(f"Using dataset folder: {config_dir}")

    print(f"Starting training process for dataset: {dataset}")
    print(f"Using ranks: {RANKS}")

    for model in MODELS:
        print("===============================================")
        print(f"Processing model: {model}")
        print("===============================================")

        pretrain_config = f"{model}_{dataset}_pretrain.yaml"
        finetune_config = f"{model}_{dataset}_finetune.yaml"

        if not os.path.isfile(pretrain_config):
            print(f"Error: Pretrain config file not found: {pretrain_config}")
            continue
        if not os.path.isfile(finetune_config):
            print(f"Error: Finetune config file not found: {finetune_config}")
            continue

        print("Found config files:")
        print(f"  - Pretrain: {pretrain_config}")
        print(f"  - Finetune: {finetune_config}")

        # Get the base resume path from config (should contain a template with some rank)
        base_resume_path = get_resume_checkpoint_path(finetune_config)

        for rank in RANKS:
            print("-----------------------------------------------")
            print(f"Processing {model} with rank: {rank}")
            print("-----------------------------------------------")

            # Generate the correct resume path for current rank
            rank_resume_path = replace_rank_in_path(base_resume_path, rank)

            if rank_resume_path and rank_resume_path.lower() != "false":
                if os.path.isdir(rank_resume_path):
                    print(f"Found existing resume_from_checkpoint path: {rank_resume_path}")
                    print("Skipping pretraining and directly using existing checkpoint for fine-tuning.")
                else:
                    print(f"resume_from_checkpoint path does not exist for rank {rank}: {rank_resume_path}")
                    print("Starting pretraining...")
                    cmd = ["bash", TRAIN_SCRIPT_REL, pretrain_config, str(rank)]
                    print(f"Command: {' '.join(cmd)}")
                    if not run_bash(cmd):
                        print("Error: Pretraining failed.")
                        continue
                    print("Pretraining completed successfully.")
            else:
                print("No valid resume_from_checkpoint found in config, starting pretraining...")
                cmd = ["bash", TRAIN_SCRIPT_REL, pretrain_config, str(rank)]
                print(f"Command: {' '.join(cmd)}")
                if not run_bash(cmd):
                    print("Error: Pretraining failed.")
                    continue
                print("Pretraining completed successfully.")

            # Step 2: update trainer_state.json using the correct rank path
            trainer_state_path = os.path.join(rank_resume_path, "trainer_state.json")
            print(f"Updating trainer_state.json at: {trainer_state_path}")
            update_save_steps(trainer_state_path)

            # Step 3: fine-tuning
            print("Starting fine-tuning...")
            cmd = ["bash", TRAIN_SCRIPT_REL, finetune_config, str(rank)]
            print(f"Command: {' '.join(cmd)}")
            if not run_bash(cmd):
                print("Error: Fine-tuning failed.")
            else:
                print("Fine-tuning completed successfully.")

            print(f"Completed processing {model} with rank {rank}")

        print(f"Completed all ranks for model: {model}")
        cleanup_pretrain_folders(dataset_folder)

    print("===============================================")
    print("All models and ranks processing completed!")
    print(f"Dataset: {dataset}")
    print(f"Models processed: {MODELS}")
    print(f"Ranks used: {RANKS}")
    print("===============================================")


if __name__ == "__main__":
    main()
