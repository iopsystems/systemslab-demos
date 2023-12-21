#!/usr/bin/env bash

set -x
set -eu

SYSTEMSLAB_URL="${SYSTEMSLAB_URL:-http://systemslab}"
SYSTEMSLAB=${SYSTEMSLAB:-systemslab}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# list of GPUs to test, these are assumed to be agent tags as well
GPU=(
    t4
    l4
)

# resolutions to test at
RESOLUTION=(
    1280x720
    1920x1080
    2560x1440
)

# quality levels
QUALITY=(
    LOW
    MEDIUM
    HIGH
    ULTRA
)

# tessellation levels
TESSELLATION=(
    DISABLED
    MODERATE
    NORMAL
    EXTREME
)

# sets the antialiasing, `0` is disabled
ANTIALIASING=(
    0
    2
    4
    8
)

# set a power limit on the Nvidia GPU, `0` is the card default
POWERCAP=(
    0
    40
    50
    60
    70
)

cd "$SCRIPT_DIR"

for gpu in "${GPU[@]}"; do
    for powercap in "${POWERCAP[@]}"; do
        for resolution in "${RESOLUTION[@]}"; do
            for quality in "${QUALITY[@]}"; do
                for tessellation in "${TESSELLATION[@]}"; do
                    for antialiasing in "${ANTIALIASING[@]}"; do
                        width=`echo $resolution | awk -Fx '{print $1}'`
                        height=`echo $resolution | awk -Fx '{print $2}'`

                        $SYSTEMSLAB submit \
                            --output-format short \
                            --param "width=$width" \
                            --param "height=$height" \
                            --param "quality=$quality" \
                            --param "tessellation=$tessellation" \
                            --param "antialiasing=$antialiasing" \
                            --param "powercap=$powercap" \
                            --param "gpu=$gpu" \
                            heaven.jsonnet
                    done
                done
            done
        done
    done
done
