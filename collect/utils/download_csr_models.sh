# use hf-mirror instead of the original
export HF_ENDPOINT="https://hf-mirror.com"
# download Mistral-7B-Instruct-v0.3
./hfd.sh mistralai/Mistral-7B-Instruct-v0.3 --local-dir ../models/Mistral-7B-Instruct-v0.3
# download BERT
./hfd.sh google-bert/bert-base-multilingual-cased --local-dir ../models/bert-base-multilingual-cased
# download gpt2
./hfd.sh openai-community/gpt2 --local-dir ../models/gpt2
# LLaMA-7B needs extra operation, therefore not included here