#!/usr/bin/env bash

echo "=============================================================================="
echo "start post-build script"

echo "Start Distribute script (appcenter-distribute.sh)"
sh ./appcenter-distribute.sh
echo "Finish Distribute script (appcenter-distribute.sh)"

echo "end post-build script"
echo "=============================================================================="
