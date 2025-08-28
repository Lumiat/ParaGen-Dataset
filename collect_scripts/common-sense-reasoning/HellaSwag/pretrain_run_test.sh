#!/bin/bash

echo "train Qwen2.5-0.5B-Instruct HellaSwag"

llamafactory-cli train qwen2.5-0.5b_hellaswag_pretrain.yaml

echo "train LLaMA-7B HellaSwag"

llamafactory-cli train llama-7b_hellaswag_pretrain.yaml

echo "train Mistral-7B-Instruct-v0.3 HellaSwag"

llamafactory-cli train mistral-7b_hellaswag_pretrain.yaml

echo "train gpt2 HellaSwag"

llamafactory-cli train gpt2_hellaswag_pretrain.yaml

echo "train gemma-3-4b HellaSwag"

llamafactory-cli train gemma-3-4b_hellaswag_pretrain.yaml

echo "train BERT HellaSwag"

llamafactory-cli train bert_hellaswag_pretrain.yaml
