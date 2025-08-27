#!/bin/bash

echo "train Qwen2.5-0.5B-Instruct WinoGrande"

llamafactory-cli train qwen2.5-0.5b_winogrande_pretrain.yaml

echo "train LLaMA-7B WinoGrande"

llamafactory-cli train llama-7b_winogrande_pretrain.yaml

echo "train Mistral-7B-Instruct-v0.3 WinoGrande"

llamafactory-cli train mistral-7b_winogrande_pretrain.yaml

echo "train gpt2 WinoGrande"

llamafactory-cli train gpt2_winogrande_pretrain.yaml

echo "train gemma-3-4b WinoGrande"

llamafactory-cli train gemma-3-4b_winogrande_pretrain.yaml

echo "train BERT WinoGrande"

llamafactory-cli train bert_winogrande_pretrain.yaml
