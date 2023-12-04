#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR"

for conns in `seq 1000 1000 1000`; do
    $SYSTEMSLAB submit                                  \
        --output-format short                           \
        --name "blabber_c${conns}_nlb" \
        --param "connections=$conns"                    \
        blabber.jsonnet
done

