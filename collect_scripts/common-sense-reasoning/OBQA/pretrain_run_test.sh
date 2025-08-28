#!/bin/bash

llamafactory-cli train qwen2.5-0.5b_obqa_pretrain.yaml

llamafactory-cli train llama-7b_obqa_pretrain.yaml

llamafactory-cli train mistral-7b_obqa_pretrain.yaml

llamafactory-cli train gpt2_obqa_pretrain.yaml

llamafactory-cli train gemma-3-4b_obqa_pretrain.yaml

llamafactory-cli train bert_obqa_pretrain.yaml
