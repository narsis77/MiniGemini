#!/bin/bash

CUDA_VISIBLE_DEVICES='0,1,2,3,4,5,6,7'
gpu_list="${CUDA_VISIBLE_DEVICES:-0}"
IFS=',' read -ra GPULIST <<< "$gpu_list"

CHUNKS=${#GPULIST[@]}

CKPT="Mini-Gemini/Mini-Gemini-8x7B"
CONFIG="minigemini/eval/MMMU/eval/configs/llava1.5.yaml"

for IDX in $(seq 0 $((CHUNKS-1))); do
    CUDA_VISIBLE_DEVICES=${GPULIST[$IDX]} python minigemini/eval/MMMU/eval/run_llava.py \
        --data_path ./data/MiniGemini-Eval/MMMU \
        --config_path $CONFIG \
        --model_path ./work_dirs/$CKPT \
        --answers-file ./work_dirs/MMMU/answers/$CKPT/${CHUNKS}_${IDX}.jsonl \
        --num-chunks $CHUNKS \
        --chunk-idx $IDX \
        --split "test" \
        --load_8bit True \
        --conv-mode mistral_instruct &
done

wait

output_file=./work_dirs/MMMU/answers/$CKPT/merge.jsonl

# Clear out the output file if it exists.
> "$output_file"

# Loop through the indices and concatenate each file.
for IDX in $(seq 0 $((CHUNKS-1))); do
    cat ./work_dirs/MMMU/answers/$CKPT/${CHUNKS}_${IDX}.jsonl >> "$output_file"
done

python minigemini/eval/MMMU/eval/convert_to_test.py --result_file $output_file --output_path ./work_dirs/MMMU/$CKPT/test.json