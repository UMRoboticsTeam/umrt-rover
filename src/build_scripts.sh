#!/usr/bin/bash
set -e

# Compile and install umrt-can-definitions
cd umrt-can-definitions
cmake -B build/
cmake --build build/
cd build
cpack -G DEB

apt install -y ./output-packages/*.deb
cd ../
rm -rf build
cd ../

# Compile and install ros2_j1939_babbler with our symbol definitions baked in
cd ros2_j1939_babbler
source /opt/ros/humble/setup.bash
colcon build --event-handlers console_direct+ --merge-install --install-base ./build-output --cmake-args -DDBC_PATH=/opt/umrt-can-definitions/share/umrt-can-definitions/Messages.stripped.sym
rm -r ./build-output/share/colcon-core
cp -r ./build-output/share/* /opt/ros/humble/share/
cp -r ./build-output/lib/* /opt/ros/humble/lib/
cp -r ./build-output/include/* /opt/ros/humble/include/
cp -r ./build-output/local/lib/python3.10/dist-packages/* /opt/ros/humble/local/lib/python3.10/dist-packages/
