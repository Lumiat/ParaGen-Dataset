#!/bin/bash

# Check parameters
if [ $# -ne 2 ]; then
    echo "Usage: $0 <yaml_file> <lora_rank>"
    echo "Example: $0 bert_arcc_pretrain.yaml 8"
    exit 1
fi

YAML_FILE=$1
LORA_RANK=$2

# Create temporary yaml file
TEMP_YAML="${YAML_FILE%.yaml}_temp_rank_${LORA_RANK}.yaml"

# Use sed to modify lora_rank, output_dir, and resume_from_checkpoint
sed -e "s/lora_rank: [0-9]*/lora_rank: ${LORA_RANK}/" \
    -e "s/_lora-rank_[0-9]*_/_lora-rank_${LORA_RANK}_/g" \
    -e "s/\(resume_from_checkpoint:[[:space:]]*[\"']\?\)[^\"']*_lora-rank_[0-9]*_\([^\"']*[\"']\?\)/\1\${resume_path_prefix}_lora-rank_${LORA_RANK}_\2/g" \
    "${YAML_FILE}" > "${TEMP_YAML}"

# More robust approach using awk for complex path replacements
awk -v rank="${LORA_RANK}" '
/^[[:space:]]*output_dir:/ {
    gsub(/_lora-rank_[0-9]+_/, "_lora-rank_" rank "_")
    print
    next
}
/^[[:space:]]*resume_from_checkpoint:/ {
    if ($0 !~ /False/ && $0 !~ /false/ && $0 !~ /null/) {
        gsub(/_lora-rank_[0-9]+_/, "_lora-rank_" rank "_")
    }
    print
    next
}
/^[[:space:]]*lora_rank:/ {
    gsub(/lora_rank:[[:space:]]*[0-9]+/, "lora_rank: " rank)
    print
    next
}
{print}
' "${YAML_FILE}" > "${TEMP_YAML}"

echo "Training with rank=${LORA_RANK}..."
echo "Generated temporary config: ${TEMP_YAML}"

# Execute training
llamafactory-cli train "${TEMP_YAML}"

# Clean up temporary file
rm "${TEMP_YAML}"
