#!/bin/bash

# check params
if [ $# -ne 2 ]; then
    echo "usage: $0 <yaml_file> <lora_rank>"
    echo "example: $0 bert_arcc_pretrain.yaml 8"
    exit 1
fi

YAML_FILE=$1
LORA_RANK=$2

# create temporary yaml file
TEMP_YAML="${YAML_FILE%.yaml}_temp_rank_${LORA_RANK}.yaml"

# use sed to change lora_rank and output_dir
sed -e "s/lora_rank: [0-9]*/lora_rank: ${LORA_RANK}/" \
    -e "s/_lora-rank_[0-9]*_/_lora-rank_${LORA_RANK}_/g" \
    "${YAML_FILE}" > "${TEMP_YAML}"

echo "training with rank=${LORA_RANK}..."
llamafactory-cli train "${TEMP_YAML}"

# delete temp file
rm "${TEMP_YAML}"
