# ================================================================
# PIXI_ROS1 — 通用工作空间 CMakeLists.txt
#
# 添加新包只需两步：
#   1. 在 "编译选项" 区域添加 option(BUILD_XXX ...)
#   2. 在 "包定义" 区域添加 add_subdirectory_if(XXX ...)
#
# 用法:
#   mkdir build && cd build
#   cmake ../src -DBUILD_ORB_SLAM2=OFF
#   make -j$(nproc)
# ================================================================
cmake_minimum_required(VERSION 3.0.2)
project(PIXI_ROS1_ws)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

if(NOT DEFINED ENV{CONDA_PREFIX})
    get_filename_component(_p "${CMAKE_CURRENT_SOURCE_DIR}/../.pixi/envs/default" ABSOLUTE)
    set(ENV{CONDA_PREFIX} "${_p}")
endif()
set(CONDA_PREFIX "$ENV{CONDA_PREFIX}")

# ================================================================
# 编译选项 — 添加新包时在此增加 option()
# ================================================================
option(BUILD_LIVOX_ROS_DRIVER "livox_ros_driver — Livox 激光雷达 ROS 驱动" ON)
option(BUILD_ORB_SLAM2         "ORB_SLAM2 — 视觉 SLAM"                    ON)

# ================================================================
# ROS / Catkin 基础
# ================================================================
find_package(catkin REQUIRED COMPONENTS
    roscpp rospy std_msgs sensor_msgs message_generation pcl_ros
)

# ---- 辅助宏：按需 add_subdirectory ----
macro(add_subdirectory_if _opt _dir)
    if(${_opt})
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_dir}/CMakeLists.txt")
            message(STATUS "  [ON]  ${_dir}")
            add_subdirectory(${_dir})
        else()
            message(WARNING "  [SKIP] ${_dir} — 目录不存在")
        endif()
    else()
        message(STATUS "  [OFF] ${_dir}")
    endif()
endmacro()

# ================================================================
# 包定义 — 每种包类型一个 section
# ================================================================
message(STATUS "")
message(STATUS "=== 包编译状态 ===")

# ----- ROS 包 (catkin) -----
add_subdirectory_if(BUILD_LIVOX_ROS_DRIVER livox_ros_driver)
# 在此处继续添加 ROS 包:
# add_subdirectory_if(BUILD_YOUR_ROS_PKG  your_ros_pkg)

# ----- 非 ROS 包 (需手动处理依赖) -----
if(BUILD_ORB_SLAM2)
    message(STATUS "  [ON]  ORB_SLAM2")

    find_package(OpenCV REQUIRED)
    find_package(Eigen3 REQUIRED)
    find_package(Pangolin REQUIRED)

    # 构建 Thirdparty/DBoW2
    set(DBOW2_SRC "${CMAKE_CURRENT_SOURCE_DIR}/ORB_SLAM2/Thirdparty/DBoW2")
    if(NOT EXISTS "${DBOW2_SRC}/lib/libDBoW2.so")
        message(STATUS "    Building DBoW2...")
        file(MAKE_DIRECTORY "${DBOW2_SRC}/build")
        execute_process(COMMAND ${CMAKE_COMMAND} .. -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_CXX_STANDARD=17 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            WORKING_DIRECTORY "${DBOW2_SRC}/build" RESULT_VARIABLE _r)
        if(_r EQUAL 0)
            execute_process(COMMAND make -j WORKING_DIRECTORY "${DBOW2_SRC}/build" RESULT_VARIABLE _r)
        endif()
        if(NOT _r EQUAL 0)
            message(FATAL_ERROR "DBoW2 构建失败")
        endif()
    endif()

    # 构建 Thirdparty/g2o
    set(G2O_SRC "${CMAKE_CURRENT_SOURCE_DIR}/ORB_SLAM2/Thirdparty/g2o")
    if(NOT EXISTS "${G2O_SRC}/lib/libg2o.so")
        message(STATUS "    Building g2o...")
        file(MAKE_DIRECTORY "${G2O_SRC}/build")
        execute_process(COMMAND ${CMAKE_COMMAND} .. -DCMAKE_BUILD_TYPE=Release
            -DCMAKE_CXX_STANDARD=17 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            WORKING_DIRECTORY "${G2O_SRC}/build" RESULT_VARIABLE _r)
        if(_r EQUAL 0)
            execute_process(COMMAND make -j WORKING_DIRECTORY "${G2O_SRC}/build" RESULT_VARIABLE _r)
        endif()
        if(NOT _r EQUAL 0)
            message(FATAL_ERROR "g2o 构建失败")
        endif()
    endif()

    add_subdirectory(ORB_SLAM2)
else()
    message(STATUS "  [OFF] ORB_SLAM2")
endif()

message(STATUS "======================")
