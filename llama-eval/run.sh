#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB_URL="${SYSTEMSLAB_URL:-http://systemslab}"
SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The GPU model to be use in the tests. Must match the agent tags
GPU=l4

# The test to run. (perplexity, hellaswag, winogrande)
TEST=perplexity

# Controls whether the model weights are automatically downloaded for each
# experiment.
AUTODOWNLOAD=1

# Specify model names to test here
MODEL=(
    Llama-7B
    Llama-13B
    Llama-30B
    Llama-2-7B
    Llama-2-13B
    OpenLlama-3B
    OpenLlama-3B-v2
    OpenLlama-7B
    OpenLlama-7B-v2
    OpenLlama-13B
)

# Specify quantization strategies to test here
QUANTIZATION=(
    Q2_K
    Q3_K_L
    Q3_K_M
    Q3_K_S
    Q4_0
    Q4_K_M
    Q4_K_S
    Q5_0
    Q5_K_M
    Q5_K_S
    Q6_K
    Q8_0
    # fp16
)

CONTEXT=(
    128
    256
    384
    512
    640
    768
    896
    1024
    1152
    1280
    1408
    1536
    1664
    1792
    1920
    2048
    2176
    2304
    2432
    2560
    2688
    2816
    2944
    3072
    3200
    3328
    3456
    3584
    3712
    3840
    3968
    4096
)

# Sets a power limit on the GPU (assumes Nvidia). A value of `0` uses the GPU's
# default power limit. This value is in Watts.
POWERCAP=0

cd "$SCRIPT_DIR"

for model in "${MODEL[@]}"; do
    for quantization in "${QUANTIZATION[@]}"; do
        for context in "${CONTEXT[@]}"; do
            $SYSTEMSLAB submit \
                --output-format short \
                --param "model=$model" \
                --param "quantization=$quantization" \
                --param "powercap=$POWERCAP" \
                --param "gpu=$GPU" \
                --param "context=$context" \
                --param "autodownload=$AUTODOWNLOAD" \
                ${TEST}.jsonnet
        done
    done
done