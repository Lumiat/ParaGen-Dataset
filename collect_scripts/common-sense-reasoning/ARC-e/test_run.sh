#!/bin/bash

echo "Pretraining Mistral..."
llamafactory-cli train mistral-7b_arce_pretrain.yaml

echo "Finetuning Mistral..."
llamafactory-cli train mistral-7b_arce_finetune.yaml

echo "Pretraining LLaMA..."
llamafactory-cli train llama-7b_arce_pretrain.yaml

echo "Finetuning LLaMA..."
llamafactory-cli train llama-7b_arce_finetune.yaml

echo "Pretraining Gemma..."
llamafactory-cli train gemma-3-4b_arce_pretrain.yaml

echo "Finetuning Gemma..."
llamafactory-cli train gemma-3-4b_arce_finetune.yaml

echo "Pretraining Qwen..."
llamafactory-cli train qwen2.5-0.5b_arce_pretrain.yaml

echo "Finetuning Qwen..."
llamafactory-cli train qwen2.5-0.5b_arce_finetune.yaml
