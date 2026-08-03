#!/bin/bash
set -e

echo "Patching livox_ros_driver for GCC 14 compatibility..."

DRIVER_CMAKE="src/third_party/livox_ros_driver/livox_ros_driver/CMakeLists.txt"

# 1. 让 find_library 也在 CONDA_PREFIX/lib 下搜索 livox_sdk
sed -i "s|find_library(LIVOX_SDK_LIBRARY liblivox_sdk_static.a /usr/local/lib)|find_library(LIVOX_SDK_LIBRARY liblivox_sdk_static.a $CONDA_PREFIX/lib /usr/local/lib)|" "$DRIVER_CMAKE"

# 2. 修复 PCL 相关兼容性问题
sed -i 's/-std=c++11/-std=c++17/' "$DRIVER_CMAKE"
sed -i 's/-Werror//g' "$DRIVER_CMAKE"

# 3. 为缺少 <memory> 的头文件添加 include
for header in \
    src/third_party/livox_ros_driver/livox_ros_driver/timesync/timesync.h \
    src/third_party/livox_ros_driver/livox_ros_driver/livox_ros_driver/lddc.h \
    src/third_party/livox_ros_driver/livox_ros_driver/livox_ros_driver/lds.h \
    src/third_party/livox_ros_driver/livox_ros_driver/livox_ros_driver/lds_lidar.h \
    src/third_party/livox_ros_driver/livox_ros_driver/livox_ros_driver/lds_hub.h \
    src/third_party/livox_ros_driver/livox_ros_driver/livox_ros_driver/ldq.h; do
    if [ -f "$header" ] && ! grep -q '<memory>' "$header"; then
        sed -i '/#include <thread>/a #include <memory>' "$header"
    fi
done

# 4. 修复 PCL shared_ptr 兼容性 — 仅 PublishCustomPointcloud 函数中使用 PointCloud::Ptr
LDDC_CPP="src/third_party/livox_ros_driver/livox_ros_driver/livox_ros_driver/lddc.cpp"
if [ -f "$LDDC_CPP" ]; then
    # 先恢复所有可能的错误修改
    sed -i 's/p_publisher->publish(\*cloud)/p_publisher->publish(cloud)/g' "$LDDC_CPP"
    sed -i 's/          \*cloud);/          cloud);/g' "$LDDC_CPP"
    # 仅修复 PublishCustomPointcloud 中的 PointCloud::Ptr（位于 FillPointsToPclMsg 之后）
    python3 -c "
import re
with open('$LDDC_CPP', 'r') as f:
    content = f.read()
# 找到 FillPointsToPclMsg 函数后的第二个 publish(cloud) 
# 使用更简单的方式：替换第343行附近的 cloud -> *cloud
lines = content.split('\n')
# PublishCustomPointcloud 函数在第274行之后，大约343行
for i, line in enumerate(lines):
    if i >= 290 and 'p_publisher->publish(cloud)' in line:
        lines[i] = line.replace('publish(cloud)', 'publish(*cloud)')
    if i >= 290 and '          cloud);' in line:
        lines[i] = line.replace('          cloud);', '          *cloud);')
with open('$LDDC_CPP', 'w') as f:
    f.write('\n'.join(lines))
print('PCL fix applied to PublishCustomPointcloud')
"
fi

echo "Sourcing ROS environment..."
source "$CONDA_PREFIX/setup.bash"

echo "Building livox_ros_driver via src/CMakeLists.txt..."
rm -rf build devel
mkdir -p build && cd build
cmake ../src -DBUILD_LIVOX_ROS_DRIVER=ON -DBUILD_ORB_SLAM2=OFF -DCATKIN_DEVEL_PREFIX=../devel -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX"
make -j$(nproc)

echo "livox_ros_driver build complete."
