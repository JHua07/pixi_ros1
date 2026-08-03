#!/bin/bash
set -e

echo "Linking livox_ros_driver to catkin workspace..."
mkdir -p devel_ws/src
rm -rf devel_ws/src/livox_ros_driver
ln -sf "$PWD/third_party/livox_ros_driver/livox_ros_driver" devel_ws/src/livox_ros_driver
echo "Linked."
