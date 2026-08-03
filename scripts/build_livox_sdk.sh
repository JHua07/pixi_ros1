#!/bin/bash
set -e

SDK_DIR="src/third_party/livox_sdk"
BUILD_DIR="$SDK_DIR/build"

echo "Patching Livox SDK for GCC 14 compatibility..."

# 1. 提升 C++ 标准到 17
sed -i 's/set(CMAKE_CXX_STANDARD 11)/set(CMAKE_CXX_STANDARD 17)/' "$SDK_DIR/CMakeLists.txt"

# 2. 让 GCC 不把 char8_t 当关键字（兼容旧 spdlog）
sed -i 's/set(CMAKE_CXX_STANDARD 17)/set(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-char8_t")/' "$SDK_DIR/CMakeLists.txt"

# 3. 移除 sdk_core 中的 -Werror，避免 c++20-compat 警告变错误
sed -i 's/-Werror//g' "$SDK_DIR/sdk_core/CMakeLists.txt"

# 4. thread_base.h 添加 <memory> 头文件
THREAD_HEADER="$SDK_DIR/sdk_core/src/base/thread_base.h"
if ! grep -q '<memory>' "$THREAD_HEADER"; then
    sed -i '/#include <thread>/i #include <memory>' "$THREAD_HEADER"
fi

echo "Building Livox SDK..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. \
    -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5

make -j$(nproc)
make install

echo "Livox SDK installed to $CONDA_PREFIX"
