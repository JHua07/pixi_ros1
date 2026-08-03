#!/bin/bash
set -e

DRIVER_DIR="third_party/livox_ros_driver"

if [ ! -d "$DRIVER_DIR" ]; then
    echo "Cloning livox_ros_driver..."
    git clone https://github.com/Livox-SDK/livox_ros_driver.git "$DRIVER_DIR"
    echo "Done."
else
    echo "livox_ros_driver already cloned at $DRIVER_DIR"
fi
