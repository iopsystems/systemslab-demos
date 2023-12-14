#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR"

SUBSCRIBERS=(
    1000
    2000
    5000
    10000
    20000
    50000
    100000
)

MAX_DELAY=(
    0
    1000
    2000
    5000
    # 10000
    # 20000
    # 50000
    # 100000
)

PUBLISH_RATE=(
    1
    2
    5
    10
    20
    50
    100
    # 200
    # 500
    # 1000
)

FANOUT=(
    7
)

MESSAGE_LEN=(
    32
)

for subscribers in "${SUBSCRIBERS[@]}"; do
    for max_delay in "${MAX_DELAY[@]}"; do
        for publish_rate in "${PUBLISH_RATE[@]}"; do
            for fanout in "${FANOUT[@]}"; do
                for message_len in "${MESSAGE_LEN[@]}"; do
                    poolsize=$(( subscribers / 5 ))
                    $SYSTEMSLAB submit \
                        --output-format short \
                        --name "blabber_v2_S5_C5_nlb_p1_s${subscribers}_pr${publish_rate}_md${max_delay}_fo${fanout}" \
                        --param "connections=$poolsize" \
                        --param "publish_rate=$publish_rate" \
                        --param "max_delay_us=$max_delay" \
                        --param "fanout=$fanout" \
                        blabber-s5-c5-nlb.jsonnet
                    poolsize=$(( subscribers / 25 ))
                    $SYSTEMSLAB submit \
                        --output-format short \
                        --name "blabber_v2_S5_C5_direct_p1_s${subscribers}_pr${publish_rate}_md${max_delay}_fo${fanout}" \
                        --param "connections=$poolsize" \
                        --param "publish_rate=$publish_rate" \
                        --param "max_delay_us=$max_delay" \
                        --param "fanout=$fanout" \
                        blabber-s5-c5-direct.jsonnet
                done
            done
        done
    done
done

