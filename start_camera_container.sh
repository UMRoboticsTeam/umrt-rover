#!/bin/bash
set -e

# Allow local root X11 display access
xhost +local:root > /dev/null 2>&1

# Default container name if not provided as $1
CONTAINER_NAME="${1:-umrt-camera}"

# Host workspace path (defaults to current directory if $2 isn't passed)
HOST_WS_INPUT="${2:-$(pwd)}"
HOST_WS="$(realpath "$HOST_WS_INPUT")"

# Define cameras as "ENV_VAR_NAME:SYMLINK_PATH"
CAMERAS=(
  "CAM1:/dev/cameras/webcam_c170"
  "CAM2:/dev/cameras/uvc_camera"
  "ARMCAM0:/dev/cameras/ra_cam0"
  "ARMCAM1:/dev/cameras/ra_cam1"
)

DOCKER_DEV_FLAGS=()
DOCKER_ENV_FLAGS=()

# Resolve cameras dynamically
for entry in "${CAMERAS[@]}"; do
  ENV_VAR="${entry%%:*}"
  SYMLINK="${entry#*:}"

  if [ -e "$SYMLINK" ]; then
    REAL_DEV=$(readlink -f "$SYMLINK")
    echo "[INFO] $ENV_VAR found at $SYMLINK -> $REAL_DEV"
    DOCKER_DEV_FLAGS+=("--device=$REAL_DEV")
    DOCKER_ENV_FLAGS+=("-e" "${ENV_VAR}=${REAL_DEV}")
  else
    echo "[WARN] $ENV_VAR ($SYMLINK) not found. Skipping."
    DOCKER_ENV_FLAGS+=("-e" "${ENV_VAR}=")
  fi
done

echo "[INFO] Mounting workspace: $HOST_WS -> /ros_ws"

docker run -it --rm \
  --name "$CONTAINER_NAME" \
  --net=host \
  --privileged \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e ROS_DOMAIN_ID=8 \
  -e FASTDDS_BUILTIN_TRANSPORTS="UDPv4" \
  -e DISPLAY="$DISPLAY" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="/dev/cameras:/dev/cameras" \
  --volume="$HOST_WS:/ros_ws:rw" \
  --workdir="/ros_ws" \
  --device=/dev/input \
  "${DOCKER_DEV_FLAGS[@]}" \
  "${DOCKER_ENV_FLAGS[@]}" \
  umrt-custom
  