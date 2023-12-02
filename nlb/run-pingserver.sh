#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR"

for conns in `seq 1000 1000 50000`; do
    $SYSTEMSLAB submit                                  \
        --output-format short                           \
        --name "pingserver_c${conns}_nlb" \
        --param "connections=$conns"                    \
        pingserver.jsonnet
done

