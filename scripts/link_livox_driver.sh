#!/bin/bash
set -e

echo "Linking livox_ros_driver to catkin workspace..."
mkdir -p src
# 防止 catkin 递归扫描 third_party 下的原始源码
touch src/third_party/CATKIN_IGNORE
rm -rf src/livox_ros_driver
ln -sf "$PWD/src/third_party/livox_ros_driver/livox_ros_driver" src/livox_ros_driver
echo "Linked."
