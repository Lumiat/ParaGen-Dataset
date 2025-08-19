#!/bin/bash

# Script for fine-tuning multiple large language models with specific dataset using LoRA
# This script handles pretraining and fine-tuning for BERT, GPT-2, LLaMA-7B, and Mistral-7B models
# Usage: ./finetune_models.sh <dataset>

# Check if dataset parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dataset>"
    echo "Example: $0 my_custom_dataset"
    exit 1
fi

DATASET=$1
RANKS=(2 4 8 16 64)
TRAIN_SCRIPT="../../utils/train_with_rank.sh"

# Define model configurations
MODELS=("bert" "gpt2" "llama-7b" "mistral-7b")

echo "Starting fine-tuning process for dataset: $DATASET"
echo "Using ranks: ${RANKS[@]}"

# Function to extract output-dir from yaml file
extract_output_dir() {
    local yaml_file=$1
    grep "output-dir:" "$yaml_file" | sed 's/.*output-dir: *//g' | tr -d '"' | tr -d "'"
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
    print(f'Error updating save_steps: {e}')
"
    else
        echo "Warning: train_state.json not found at: $json_file"
    fi
}

# Function to get resume_from_checkpoint path from yaml file
get_resume_checkpoint_path() {
    local yaml_file=$1
    grep "resume_from_checkpoint:" "$yaml_file" | sed 's/.*resume_from_checkpoint: *//g' | tr -d '"' | tr -d "'"
}

# Main processing loop
for model in "${MODELS[@]}"; do
    echo "==============================================="
    echo "Processing model: $model"
    echo "==============================================="
    
    # Define pretrain and finetune config files
    pretrain_config="${model}_${DATASET}_pretrain.yaml"
    finetune_config="${model}_${DATASET}_finetune.yaml"
    
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
        
        # Step 1: Check if pretrain output directory exists
        base_output_dir=$(extract_output_dir "$pretrain_config")
        if [ -z "$base_output_dir" ]; then
            echo "Error: Could not extract output-dir from $pretrain_config"
            continue
        fi
        
        # Replace lora_rank number in path with current rank
        rank_output_dir=$(echo "$base_output_dir" | sed "s/lora_rank[0-9]\+/lora_rank$rank/g")
        
        echo "Checking if output directory exists: $rank_output_dir"
        
        if [ -d "$rank_output_dir" ]; then
            echo "Output directory exists, skipping pretraining for $model with rank $rank"
        else
            echo "Output directory does not exist, starting pretraining..."
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
        
        # Step 2: Update save_steps in train_state.json from finetune config
        resume_path=$(get_resume_checkpoint_path "$finetune_config")
        if [ -n "$resume_path" ]; then
            train_state_path="${resume_path}/train_state.json"
            echo "Updating train_state.json at: $train_state_path"
            update_save_steps "$train_state_path"
        else
            echo "Warning: Could not find resume_from_checkpoint path in $finetune_config"
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
