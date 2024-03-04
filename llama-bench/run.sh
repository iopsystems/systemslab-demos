#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB_URL="${SYSTEMSLAB_URL:-http://systemslab}"
SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The GPU models to be tested. Must match the agent tags
GPU=(
    l4
)

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
)

# Sets a power limit on the GPU (assumes Nvidia). A value of `0` uses the GPU's
# default power limit. This value is in Watts.
POWERCAP=(
    0
    # 40
    # 45
    # 50
    # 55
    # 60
    # 65
    # 70
    # 150
    # 200
    # 250
    # 300
    # 350
    # 400
)

# The number of tokens to generate per repetition
LENGTH=(
    256
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
                        --param "autodownload=$AUTODOWNLOAD" \
                        llama_bench.jsonnet
                done
            done
        done
    done
done