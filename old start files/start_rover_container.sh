#!/bin/bash
set -e

# Allow local root X11 display access
xhost +local:root > /dev/null 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default container name if not provided as $1
CONTAINER_NAME="${1:-umrt-rover}"

# Host workspace path (defaults to current directory if $2 isn't passed)
HOST_WS_INPUT="${2:-$(pwd)}"
HOST_WS="$(realpath "$HOST_WS_INPUT")"


echo "[INFO] Mounting workspace: $HOST_WS -> /ros_ws"

docker run -it --rm \
  --name "$CONTAINER_NAME" \
  --network bridge_lo \
  --ip 10.0.10.59 \
  -e ROS_DOMAIN_ID=2 \
  -e ROS_LOCALHOST_ONLY=0 \
  -e RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
  -e ROUTE_POLICY=drop-default \
  --privileged \
  --runtime=nvidia \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e DISPLAY="$DISPLAY" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="$HOST_WS:/ros_ws:rw" \
  --volume="$SCRIPT_DIR/../umrt-network-bridge-tests/config/rover-lo.yaml:/opt/ros/humble/share/network_bridge/launch/rover-lo.yaml" \
  --volume="$SCRIPT_DIR/../umrt-network-bridge-tests/config/rover-lo.launch.py:/opt/ros/humble/share/network_bridge/launch/rover-lo.launch.py" \
  --workdir="/ros_ws" \
  --device=/dev/input \
  ghcr.io/umroboticsteam/umrt-build:comms-network-bridge \
  /bin/bash
