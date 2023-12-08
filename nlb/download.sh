#!/usr/bin/env bash -v

set -euo pipefail

VERBOSE=${VERBOSE:-0}

if [ "$VERBOSE" -ne 0 ]; then
    set -x
fi

SYSTEMSLAB_URL="${SYSTEMSLAB_URL:-http://localhost:3000}"
EXPERIMENTS=$(cat "$1")
OUTDIR="$2"

mkdir -p "$OUTDIR"

for expt in $EXPERIMENTS; do
    name=$(curl -s "$SYSTEMSLAB_URL/api/v1/experiment/$expt" | jq -r .name)
    C=0
    for artifact in `systemslab artifact list --experiment "$expt" | grep logs.json | cut -d ' ' -f 1`; do

        echo "Downloading $artifact $name.json"
        systemslab artifact download --artifact "$artifact" -o "$OUTDIR/$name-$C.json"

        ((C++))
    done
done
