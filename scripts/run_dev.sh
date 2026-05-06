#!/bin/bash

source .venv/bin/activate
# set up CUDA_VISIBLE_DEVICES, 
# PBS Pro sets it to some non-integer ids
source scripts/set_devices.sh

# Debugging knobs for API worker processes (optional).
export VLLM_DEBUGPY_ENABLED=1
# export VLLM_DEBUGPY_HOST=127.0.0.1
# export VLLM_DEBUGPY_BASE_PORT=5678
# export VLLM_DEBUGPY_WAIT_FOR_CLIENT=1
# export VLLM_DEBUGPY_WORKER_INDEX=0  # or "all"

# python vllm/entrypoints/cli/main.py --version

python vllm/entrypoints/cli/main.py serve \
    Qwen/Qwen3-Coder-30B-A3B-Instruct \
    --enable-auto-tool-choice --tool-call-parser qwen3_coder \
    --tensor-parallel-size 1 \
    --data-parallel-size $num_devices \
    --enable-expert-parallel #\
    # --all2all-backend pplx
