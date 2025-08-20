#!/bin/bash

# Script for fine-tuning multiple large language models with specific dataset using LoRA
# This script handles pretraining and fine-tuning for BERT, GPT-2, LLaMA-7B, and Mistral-7B models
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
DATASET_MAPPING["boolq"]="BOOLQ"

# Get the mapped folder name
DATASET_FOLDER=${DATASET_MAPPING[$DATASET]}
if [ -z "$DATASET_FOLDER" ]; then
    echo "Error: Unknown dataset '$DATASET'. Supported datasets: ${!DATASET_MAPPING[@]}"
    exit 1
fi

# Get current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the target config directory
CONFIG_DIR="$SCRIPT_DIR/DATASET[$DATASET_FOLDER]"

# Check if the dataset folder exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Dataset folder not found: $CONFIG_DIR"
    exit 1
fi

echo "Using dataset folder: $CONFIG_DIR"

# Define model configurations
# MODELS=("bert" "gpt2" "llama-7b" "mistral-7b" "qwen2.5-0.5b")
MODELS=("qwen2.5-0.5b")

echo "Starting training process for dataset: $DATASET"
echo "Using ranks: ${RANKS[@]}"

# Function to extract output_dir from yaml file
extract_output_dir() {
    local yaml_file=$1
    grep "output_dir:" "$yaml_file" | sed 's/.*output_dir: *//g' | tr -d '"' | tr -d "'"
}

# Function to update save_steps in train_state.json
update_save_steps() {
    local json_file=$1
    if [ -f "$json_file" ]; then
        echo "Updating save_steps to 1 in: $json_file"
        # Create a temporary file with updated save_steps
        python3 -c "
import json
import sys

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
        if [ $? -ne 0 ]; then
            echo "Error: Failed to update save_steps in $json_file"
            return 1
        fi
    else
        echo "Warning: train_state.json not found at: $json_file"
        return 1
    fi
}

# Function to get resume_from_checkpoint path from yaml file
get_resume_checkpoint_path() {
    local yaml_file=$1
    grep "resume_from_checkpoint:" "$yaml_file" | sed 's/.*resume_from_checkpoint: *//g' | tr -d '"' | tr -d "'" | sed 's/^[ \t]*//;s/[ \t]*$//'
}

# Main processing loop
for model in "${MODELS[@]}"; do
    echo "==============================================="
    echo "Processing model: $model"
    echo "==============================================="
    
    # Define pretrain and finetune config files (now looking in the dataset folder)
    pretrain_config="${CONFIG_DIR}/${model}_${DATASET}_pretrain.yaml"
    finetune_config="${CONFIG_DIR}/${model}_${DATASET}_finetune.yaml"
    
    # Check if config files exist
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
    
    # Process each rank
    for rank in "${RANKS[@]}"; do
        echo "-----------------------------------------------"
        echo "Processing $model with rank: $rank"
        echo "-----------------------------------------------"
        
        # Step 1: Check if finetune output directory exists to determine if we need pretraining
        finetune_output_dir=$(extract_output_dir "$finetune_config")
        if [ -z "$finetune_output_dir" ]; then
            echo "Error: Could not extract output_dir from $finetune_config"
            continue
        fi
        
        # Replace lora_rank number in finetune output path with current rank
        rank_finetune_output_dir=$(echo "$finetune_output_dir" | sed "s/lora-rank_[0-9]\+/lora-rank_$rank/g")
        
        echo "Checking if finetune output directory exists: $rank_finetune_output_dir"
        
        if [ -d "$rank_finetune_output_dir" ]; then
            echo "Finetune output directory exists, skipping pretraining for $model with rank $rank"
        else
            echo "Finetune output directory does not exist, starting pretraining..."
            echo "Command: bash $TRAIN_SCRIPT $pretrain_config $rank"
            
            # Execute pretraining
            bash "$TRAIN_SCRIPT" "$pretrain_config" "$rank"
            
            if [ $? -eq 0 ]; then
                echo "Pretraining completed successfully for $model with rank $rank"
            else
                echo "Error: Pretraining failed for $model with rank $rank"
                continue
            fi
        fi
        
        # Step 2: Update save_steps in trainer_state.json from finetune config
        resume_path=$(get_resume_checkpoint_path "$finetune_config")
        if [ -n "$resume_path" ] && [ "$resume_path" != "False" ] && [ "$resume_path" != "false" ]; then
            # Replace lora_rank number in resume path with current rank
            rank_resume_path=$(echo "$resume_path" | sed "s/lora-rank_[0-9]\+/lora-rank_$rank/g")
            trainer_state_path="${rank_resume_path}/trainer_state.json"
            echo "Updating trainer_state.json at: $trainer_state_path"
            update_save_steps "$trainer_state_path"
        else
            echo "Warning: No valid resume_from_checkpoint path found in $finetune_config"
        fi
        
        # Step 3: Execute fine-tuning
        echo "Starting fine-tuning..."
        echo "Command: bash $TRAIN_SCRIPT $finetune_config $rank"
        
        bash "$TRAIN_SCRIPT" "$finetune_config" "$rank"
        
        if [ $? -eq 0 ]; then
            echo "Fine-tuning completed successfully for $model with rank $rank"
        else
            echo "Error: Fine-tuning failed for $model with rank $rank"
        fi
        
        echo "Completed processing $model with rank $rank"
    done
    
    echo "Completed all ranks for model: $model"
done

echo "==============================================="
echo "All models and ranks processing completed!"
echo "Dataset: $DATASET"
echo "Models processed: ${MODELS[@]}"
echo "Ranks used: ${RANKS[@]}"
echo "==============================================="
