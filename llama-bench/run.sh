#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB_URL="${SYSTEMSLAB_URL:-http://systemslab}"
SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The GPU models to be tested. Must match the agent tags
GPU=(
    rtx2080ti
)

# Specify model names to test here
MODEL=(
    Llama-2-7B
    # Llama-2-13B
    # CodeLlama-7B
    # CodeLlama-13B
    # CodeLlama-34B
    # CodeLlama-7B-Instruct
    # CodeLlama-13B-Instruct
    # CodeLlama-34B-Instruct
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
)

# Sets a power limit on the GPU (assumes Nvidia). A value of `0` uses the GPU's
# default power limit. This value is in Watts.
POWERCAP=(
    0
    150
    200
    250
    300
)

# The number of tokens to generate per repetition
LENGTH=(
    128
    256
    512
)

# The number of repetitions in the test
REPETITIONS=15

cd "$SCRIPT_DIR"

for gpu in "${GPU[@]}"; do
    for model in "${MODEL[@]}"; do
        for quantization in "${QUANTIZATION[@]}"; do
            for powercap in "${POWERCAP[@]}"; do
                for length in "${LENGTH[@]}"; do
                    $SYSTEMSLAB submit \
                        --output-format short \
                        --param "model=$model" \
                        --param "quantization=$quantization" \
                        --param "powercap=$powercap" \
                        --param "length=$length" \
                        --param "repetitions=$REPETITIONS" \
                        --param "gpu=$gpu" \
                        llama_bench.jsonnet
                done
            done
        done
    done
done