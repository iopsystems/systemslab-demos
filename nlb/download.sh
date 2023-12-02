#!/usr/bin/env bash

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
    artifact=$(systemslab artifact list --experiment "$expt" | grep output.json | cut -d ' ' -f 1)

    echo "Downloading $name.json"
    systemslab artifact download --artifact "$artifact" -o "$OUTDIR/$name.json"
done
