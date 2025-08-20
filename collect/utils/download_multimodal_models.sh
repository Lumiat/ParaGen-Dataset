# use hf-mirror instead of the original
export HF_ENDPOINT="https://hf-mirror.com"
# download Qwen2.5-VL-3B-Instruct
./hfd.sh Qwen/Qwen2.5-VL-3B-Instruct --local-dir ../models/Qwen2.5-VL-3B-Instruct
# download LLaVA
./hfd.sh llava-hf/llava-1.5-7b-hf --local-dir ../models/llava-1.5-7b-hf
# download InternVL
./hfd.sh OpenGVLab/InternVL2-8B --local-dir ../models/InternVL2-8B
# download MiniGPT4
./hfd.sh Vision-CAIR/MiniGPT-4 --local-dir ../models/MiniGPT4
