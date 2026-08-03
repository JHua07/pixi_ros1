#!/bin/bash
set -e
PANGOLIN_DIR="src/third_party/Pangolin"

if [ ! -d "$PANGOLIN_DIR" ]; then
    echo "Cloning Pangolin..."
    git clone --depth 1 https://github.com/stevenlovegrove/Pangolin.git "$PANGOLIN_DIR"
fi

echo "Patching Pangolin for GCC 14..."
# 修复 =maybe-uninitialized 和 =vla 缺少 -W 前缀的 bug
sed -i 's/(=maybe-uninitialized)/(-Wmaybe-uninitialized)/' "$PANGOLIN_DIR/CMakeLists.txt"
sed -i 's/(=vla)/(-Wvla)/' "$PANGOLIN_DIR/CMakeLists.txt"
# 移除 -Werror
find "$PANGOLIN_DIR" -name "CMakeLists.txt" -exec sed -i 's/-Werror//g' {} \;

rm -rf "$PANGOLIN_DIR/build"
mkdir -p "$PANGOLIN_DIR/build"
cd "$PANGOLIN_DIR/build"

cmake .. \
    -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF \
    -DBUILD_PANGOLIN_PYTHON=OFF \
    -DBUILD_PANGOLIN_VARS=OFF \
    -DBUILD_PANGOLIN_VIDEO=OFF \
    -DOPENGL_egl_LIBRARY="$CONDA_PREFIX/lib/libEGL.so" \
    -DOPENGL_opengl_LIBRARY="$CONDA_PREFIX/lib/libOpenGL.so" \
    -DOPENGL_GLU_LIBRARY="$CONDA_PREFIX/lib/libGLU.so" \
    -DOPENGL_INCLUDE_DIR=/usr/include

make -j$(nproc)
make install
echo "Pangolin installed to $CONDA_PREFIX"
