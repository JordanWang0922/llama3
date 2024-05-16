#!/usr/bin/env bash

# 设置脚本退出条件
set -e

read -p "Enter the URL from email: " PRESIGNED_URL
echo ""

read -p "Enter the list of models to download without spaces (8B,8B-instruct,7B,7B-instruct), or press Enter for all: " MODEL_SIZE
echo ""

# 设置目标文件夹路径
TARGET_FOLDER="/e/AI_model_llama/llama3_model"
mkdir -p ${TARGET_FOLDER}

if [[ $MODEL_SIZE == "" ]]; then
    MODEL_SIZE="8B,8B-instruct,7B,7B-instruct"
fi

echo "Downloading LICENSE and Acceptable Usage Policy"
curl -L -o ${TARGET_FOLDER}/LICENSE "${PRESIGNED_URL}/*/LICENSE"
curl -L -o ${TARGET_FOLDER}/USE_POLICY.md "${PRESIGNED_URL}/*/USE_POLICY.md"

for m in ${MODEL_SIZE//,/ }
do
    if [[ $m == "8B" ]] || [[ $m == "8b" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-llama-3-8B"
        MODEL_PATH="8b_pre_trained"
    elif [[ $m == "8B-instruct" ]] || [[ $m == "8B-Instruct" ]] || [[ $m == "8b-instruct" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-llama-3-8B-Instruct"
        MODEL_PATH="8b_instruction_tuned"
    elif [[ $m == "7B" ]] || [[ $m == "7b" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-llama-3-7B"
        MODEL_PATH="7b_pre_trained"
    elif [[ $m == "7B-instruct" ]] || [[ $m == "7B-Instruct" ]] || [[ $m == "7b-instruct" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-llama-3-7B-Instruct"
        MODEL_PATH="7b_instruction_tuned"
    fi

    echo "Downloading ${MODEL_PATH}"
    mkdir -p ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}

    for s in $(seq -f "%03g" 0 ${SHARD})
    do
        curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/consolidated.${s}.pth "${PRESIGNED_URL}/*/${MODEL_PATH}/consolidated.${s}.pth"
    done

    curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/params.json "${PRESIGNED_URL}/*/${MODEL_PATH}/params.json"
    curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/tokenizer.model "${PRESIGNED_URL}/*/${MODEL_PATH}/tokenizer.model"
    curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/checklist.chk "${PRESIGNED_URL}/*/${MODEL_PATH}/checklist.chk"

    echo "Checking checksums"
    CPU_ARCH=$(uname -m)
    if [[ $CPU_ARCH == "arm64" ]]; then
        (cd ${TARGET_FOLDER}/${MODEL_FOLDER_PATH} && md5 checklist.chk)
    else
        (cd ${TARGET_FOLDER}/${MODEL_FOLDER_PATH} && md5sum -c checklist.chk)
    fi
done
