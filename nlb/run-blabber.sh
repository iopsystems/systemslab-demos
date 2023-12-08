#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR"

CONNECTIONS=(
    200
    400
    600
    800
    1000
    1200
    1400
    1600
    1800
    2000
    4000
    6000
    8000
    10000
    12000
    14000
    16000
    18000
    20000
)

# CONNECTIONS=(
#     500
#     1000
#     1500
#     2000
#     2500
#     3000
#     3500
#     4000
#     4500
#     5000
#     10000
# )

# CONNECTIONS=(
#     1000
#     2000
#     3000
#     4000
#     5000
#     6000
#     7000
#     8000
#     9000
#     10000
#     20000
# )

for conns in "${CONNECTIONS[@]}"; do
    $SYSTEMSLAB submit                                  \
        --output-format short                           \
        --name "blabber_S1_C5_c${conns}_md10_nlb" \
        --param "connections=$conns"                    \
        blabber-fan-out.jsonnet
done
