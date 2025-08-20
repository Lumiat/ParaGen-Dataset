# use hf-mirror instead of the original
export HF_ENDPOINT="https://hf-mirror.com"
# download Mistral-7B-v0.3
./hfd.sh mistralai/Mistral-7B-v0.3 --hf_username xxx --hf_token xxx --local-dir ../models/Mistral-7B-v0.3
# download BERT
./hfd.sh google-bert/bert-base-multilingual-cased --local-dir ../models/bert-base-multilingual-cased
# download gpt2
./hfd.sh openai-community/gpt2 --local-dir ../models/gpt2
# download LLaMA-7B
./hfd.sh huggyllama/llama-7b --local-dir ../models/llama-7b
# download gemma-3-4b-it
./hfd.sh google/gemma-3-4b-it --hf_username xxx --hf_token xxx --local-dir ../models/gemma-3-4b-it
