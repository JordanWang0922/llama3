#!/usr/bin/env bash

# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

set -e

# 从用户输入中获取Presigned URL
read -p "Enter the URL from email: " PRESIGNED_URL
echo ""
# 从用户输入中获取要下载的模型列表
read -p "Enter the list of models to download without spaces (8B,8B-instruct,70B,70B-instruct), or press Enter for all: " MODEL_SIZE

# 设置目标文件夹路径
TARGET_FOLDER="/e/AI_model_llama/llama3_model"
mkdir -p ${TARGET_FOLDER}

# 如果用户没有输入模型列表，则使用默认模型列表
if [[ $MODEL_SIZE == "" ]]; then
    MODEL_SIZE="8B,8B-instruct,70B,70B-instruct"
fi

# 下载许可证和可接受使用政策
echo "Downloading LICENSE and Acceptable Usage Policy"
curl -L -o ${TARGET_FOLDER}/LICENSE "${PRESIGNED_URL/'*'/'LICENSE'}"
curl -L -o ${TARGET_FOLDER}/USE_POLICY "${PRESIGNED_URL/'*'/'USE_POLICY'}"

# 下载模型文件
for m in ${MODEL_SIZE//,/ }
do
    if [[ $m == "8B" ]] || [[ $m == "8b" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-Llama-3-8B"
        MODEL_PATH="8b_pre_trained"
    elif [[ $m == "8B-instruct" ]] || [[ $m == "8b-instruct" ]] || [[ $m == "8b-Instruct" ]] || [[ $m == "8B-Instruct" ]]; then
        SHARD=0
        MODEL_FOLDER_PATH="Meta-Llama-3-8B-Instruct"
        MODEL_PATH="8b_instruction_tuned"
    elif [[ $m == "70B" ]] || [[ $m == "70b" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-Llama-3-70B"
        MODEL_PATH="70b_pre_trained"
    elif [[ $m == "70B-instruct" ]] || [[ $m == "70b-instruct" ]] || [[ $m == "70b-Instruct" ]] || [[ $m == "70B-Instruct" ]]; then
        SHARD=7
        MODEL_FOLDER_PATH="Meta-Llama-3-70B-Instruct"
        MODEL_PATH="70b_instruction_tuned"
    fi

    echo "Downloading ${MODEL_PATH}"
    mkdir -p ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}

    for s in $(seq -f "%03g" 0 ${SHARD})
    do
        curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/consolidated.${s}.pth "${PRESIGNED_URL/'*'/'${MODEL_PATH}/consolidated.${s}.pth'}"
    done

    curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/params.json "${PRESIGNED_URL/'*'/'${MODEL_PATH}/params.json'}"
    curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/tokenizer.model "${PRESIGNED_URL/'*'/'${MODEL_PATH}/tokenizer.model'}"
    curl -L -o ${TARGET_FOLDER}/${MODEL_FOLDER_PATH}/checklist.chk "${PRESIGNED_URL/'*'/'${MODEL_PATH}/checklist.chk'}"

    echo "Checking checksums"
    CPU_ARCH=$(uname -m)
    if [[ "$CPU_ARCH" == "arm64" ]]; then
      (cd ${TARGET_FOLDER}/${MODEL_FOLDER_PATH} && md5 checklist.chk)
    else
      (cd ${TARGET_FOLDER}/${MODEL_FOLDER_PATH} && md5sum -c checklist.chk)
    fi
done
