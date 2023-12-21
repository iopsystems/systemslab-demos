#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB_URL="${SYSTEMSLAB_URL:-http://systemslab}"
SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

MODEL=(
    # Llama-2
    # CodeLlama
    CodeLlama-7B-Instruct
    CodeLlama-13B-Instruct
    CodeLlama-34B-Instruct
)

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

POWERCAP=(
    150
    200
    250
    300
)

LENGTH=(
    128
    256
    512
)

REPETITIONS=15

cd "$SCRIPT_DIR"

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
                    llama_bench.jsonnet
            done
        done
    done
done
