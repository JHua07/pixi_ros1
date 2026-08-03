#!/bin/bash
set -e

SDK_DIR="third_party/livox_sdk"

if [ ! -d "$SDK_DIR" ]; then
    echo "Cloning Livox-SDK..."
    git clone https://github.com/Livox-SDK/Livox-SDK.git "$SDK_DIR"
    echo "Done."
else
    echo "livox_sdk already cloned at $SDK_DIR"
fi
