#!/bin/bash

# Script for fine-tuning multiple large language models with specific dataset using LoRA
# This script handles pretraining and fine-tuning for BERT, GPT-2, LLaMA-7B, Mistral-7B, Qwen2.5, and Gemma models
# Usage: ./collect_all_datasets.sh <dataset>

# Check if dataset parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dataset>"
    echo "Example: $0 arcc"
    exit 1
fi

DATASET=$1
RANKS=(2 4 8 16 64)
TRAIN_SCRIPT="../../utils/train_with_rank.sh"

# Define dataset to folder mapping
declare -A DATASET_MAPPING
DATASET_MAPPING["arcc"]="ARC-c"
DATASET_MAPPING["arce"]="ARC-e"
DATASET_MAPPING["obqa"]="OBQA"
DATASET_MAPPING["piqa"]="PIQA"
DATASET_MAPPING["hellaswag"]="HellaSwag"
DATASET_MAPPING["winogrande"]="WinoGrande"
DATASET_MAPPING["boolq"]="BoolQ"

# Get the mapped folder name
DATASET_FOLDER=${DATASET_MAPPING[$DATASET]}
if [ -z "$DATASET_FOLDER" ]; then
    echo "Error: Unknown dataset '$DATASET'. Supported datasets: ${!DATASET_MAPPING[@]}"
    exit 1
fi

# Get current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the target config directory (absolute path)
CONFIG_DIR="$SCRIPT_DIR/$DATASET_FOLDER"

# Check if the dataset folder exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Dataset folder not found: $CONFIG_DIR"
    exit 1
fi

# Change working directory to the dataset folder
echo "Changing working directory to: $CONFIG_DIR"
cd "$CONFIG_DIR"

# Verify working directory change
if [ "$(pwd)" != "$CONFIG_DIR" ]; then
    echo "Error: Failed to change working directory to $CONFIG_DIR"
    exit 1
fi

echo "Current working directory: $(pwd)"
echo "Using dataset folder: $CONFIG_DIR"

# Define model configurations
MODELS=("bert" "gpt2" "llama-7b" "mistral-7b" "qwen2.5-0.5b" "gemma-3-4b")

echo "Starting training process for dataset: $DATASET"
echo "Using ranks: ${RANKS[@]}"

# Function to extract output_dir from yaml file
extract_output_dir() {
    local yaml_file=$1
    grep "output_dir:" "$yaml_file" | sed 's/.*output_dir: *//g' | tr -d '"' | tr -d "'"
}

# Function to get resume_from_checkpoint path from yaml file
get_resume_checkpoint_path() {
    local yaml_file=$1
    grep "resume_from_checkpoint:" "$yaml_file" | sed 's/.*resume_from_checkpoint: *//g' | tr -d '"' | tr -d "'" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Function to update save_steps in trainer_state.json
update_save_steps() {
    local json_file=$1
    if [ -f "$json_file" ]; then
        echo "Updating save_steps to 1 in: $json_file"
        python3 -c "
import json, sys
try:
    with open('$json_file', 'r') as f:
        data = json.load(f)
    data['save_steps'] = 1
    with open('$json_file', 'w') as f:
        json.dump(data, f, indent=2)
    print('Successfully updated save_steps to 1')
except Exception as e:
    print(f'Error updating save_steps: {e}', file=sys.stderr)
    sys.exit(1)
"
    else
        echo "Warning: trainer_state.json not found at: $json_file"
    fi
}

# Function to clean up pretrain folders
cleanup_pretrain_folders() {
    local dataset_folder=$1
    local pretrain_save_dir="/research-intern05/xjy/ParaGen-Dataset/saves/common-sense-reasoning/$dataset_folder"
    
    echo "-----------------------------------------------"
    echo "Cleaning up pretrain folders in: $pretrain_save_dir"
    echo "-----------------------------------------------"
    
    if [ -d "$pretrain_save_dir" ]; then
        pretrain_dirs=$(find "$pretrain_save_dir" -maxdepth 1 -type d -name "*pretrain" 2>/dev/null)
        if [ -n "$pretrain_dirs" ]; then
            echo "Found pretrain directories to remove:"
            echo "$pretrain_dirs"
            echo "$pretrain_dirs" | while read -r dir; do
                if [ -d "$dir" ]; then
                    echo "Removing: $dir"
                    rm -rf "$dir"
                    [ $? -eq 0 ] && echo "Successfully removed: $dir" || echo "Error: Failed to remove $dir"
                fi
            done
        else
            echo "No pretrain directories found to remove in: $pretrain_save_dir"
        fi
    else
        echo "Warning: Save directory does not exist: $pretrain_save_dir"
    fi
}

# Main processing loop
for model in "${MODELS[@]}"; do
    echo "==============================================="
    echo "Processing model: $model"
    echo "==============================================="
    
    pretrain_config="${model}_${DATASET}_pretrain.yaml"
    finetune_config="${model}_${DATASET}_finetune.yaml"
    
    if [ ! -f "$pretrain_config" ]; then
        echo "Error: Pretrain config file not found: $pretrain_config"
        continue
    fi
    if [ ! -f "$finetune_config" ]; then
        echo "Error: Finetune config file not found: $finetune_config"
        continue
    fi
    
    echo "Found config files:"
    echo "  - Pretrain: $pretrain_config"
    echo "  - Finetune: $finetune_config"
    
    for rank in "${RANKS[@]}"; do
        echo "-----------------------------------------------"
        echo "Processing $model with rank: $rank"
        echo "-----------------------------------------------"
        
        # Step 1: Check if resume_from_checkpoint path already exists
        resume_path=$(get_resume_checkpoint_path "$finetune_config")
        if [ -n "$resume_path" ] && [ "$resume_path" != "False" ] && [ "$resume_path" != "false" ]; then
            rank_resume_path=$(echo "$resume_path" | sed "s/lora-rank_[0-9]\+/lora-rank_$rank/g")
            if [ -d "$rank_resume_path" ]; then
                echo "Found existing resume_from_checkpoint path: $rank_resume_path"
                echo "Skipping pretraining and directly using existing checkpoint for fine-tuning."
            else
                echo "resume_from_checkpoint path does not exist for rank $rank, starting pretraining..."
                RELATIVE_TRAIN_SCRIPT="../../../utils/train_with_rank.sh"
                echo "Command: bash $RELATIVE_TRAIN_SCRIPT $pretrain_config $rank"
                bash "$RELATIVE_TRAIN_SCRIPT" "$pretrain_config" "$rank"
                [ $? -eq 0 ] && echo "Pretraining completed successfully." || { echo "Error: Pretraining failed."; continue; }
            fi
        else
            echo "No valid resume_from_checkpoint found in config, starting pretraining..."
            RELATIVE_TRAIN_SCRIPT="../../../utils/train_with_rank.sh"
            echo "Command: bash $RELATIVE_TRAIN_SCRIPT $pretrain_config $rank"
            bash "$RELATIVE_TRAIN_SCRIPT" "$pretrain_config" "$rank"
            [ $? -eq 0 ] && echo "Pretraining completed successfully." || { echo "Error: Pretraining failed."; continue; }
        fi
        
        # Step 2: Update save_steps in trainer_state.json
        rank_resume_path=$(echo "$resume_path" | sed "s/lora-rank_[0-9]\+/lora-rank_$rank/g")
        trainer_state_path="${rank_resume_path}/trainer_state.json"
        echo "Updating trainer_state.json at: $trainer_state_path"
        update_save_steps "$trainer_state_path"
        
        # Step 3: Run fine-tuning
        echo "Starting fine-tuning..."
        RELATIVE_TRAIN_SCRIPT="../../../utils/train_with_rank.sh"
        echo "Command: bash $RELATIVE_TRAIN_SCRIPT $finetune_config $rank"
        bash "$RELATIVE_TRAIN_SCRIPT" "$finetune_config" "$rank"
        [ $? -eq 0 ] && echo "Fine-tuning completed successfully." || echo "Error: Fine-tuning failed."
        
        echo "Completed processing $model with rank $rank"
    done
    
    echo "Completed all ranks for model: $model"
    cleanup_pretrain_folders "$DATASET_FOLDER"
done

echo "==============================================="
echo "All models and ranks processing completed!"
echo "Dataset: $DATASET"
echo "Models processed: ${MODELS[@]}"
echo "Ranks used: ${RANKS[@]}"
echo "==============================================="
