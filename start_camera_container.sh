#!/bin/bash
xhost +local:root

CAM1_SYMLINK="/dev/cameras/webcam_c170"
CAM2_SYMLINK="/dev/cameras/uvc_camera"
ARMCAM0_SYMLINK="/dev/cameras/ra_cam0"
ARMCAM1_SYMLINK="/dev/cameras/ra_cam1"

CAM1=""
CAM2=""
ARMCAM0=""
ARMCAM1=""

# Check and resolve camera symlinks if they exist
if [ -e "$CAM1_SYMLINK" ]; then
  CAM1=$(readlink -f "$CAM1_SYMLINK")
  CAM1_ARG="--device=$CAM1"
else
  echo "Warning CAM1: Webcam C170 not found. Continuing without it."
  CAM1_ARG=""
fi

if [ -e "$CAM2_SYMLINK" ]; then
  CAM2=$(readlink -f "$CAM2_SYMLINK")
  CAM2_ARG="--device=$CAM2"
else
  echo "Warning CAM2: UVC Camera not found. Continuing without it."
  CAM2_ARG=""
fi

if [ -e "$ARMCAM0_SYMLINK" ]; then
  ARMCAM0=$(readlink -f "$ARMCAM0_SYMLINK")
  ARMCAM0_ARG="--device=$ARMCAM0"
else
  echo "Warning ARMCAM0: Robotic Arm Camera 0 not found. Continuing without it."
  ARMCAM0_ARG=""
fi

if [ -e "$ARMCAM1_SYMLINK" ]; then
  ARMCAM1=$(readlink -f "$ARMCAM1_SYMLINK")
  ARMCAM1_ARG="--device=$ARMCAM1"
else
  echo "Warning ARMCAM1: Robotic Arm Camera 1 not found. Continuing without it."
  ARMCAM1_ARG=""
fi

docker run -it --rm \
  --name $1 \
  --net=host \
  --privileged \
  --gpus all \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e ROS_DOMAIN_ID=8 \
  -e FASTDDS_BUILTIN_TRANSPORTS="UDPv4" \
  --device=/dev/ttyUSB0:/dev/ttyUSB0 \
  $CAM1_ARG \
  $CAM2_ARG \
  $ARMCAM0_ARG \
  $ARMCAM1_ARG \
  -e DISPLAY=$DISPLAY \
  -e CAM1="$CAM1" \
  -e CAM2="$CAM2" \
  -e ARMCAM0="$ARMCAM0" \
  -e ARMCAM1="$ARMCAM1" \
  --env="QT_X11_NO_MITSHM=1" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  -v $ROS_WORKSPACE/umrt-rover/fastdds_profiles/fastdds_HiBW.xml:/fastdds_HiBW.xml:ro \
  -e RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
  -e FASTRTPS_DEFAULT_PROFILES_FILE=/fastdds_HiBW.xml \
  ghcr.io/umroboticsteam/umrt-rover:main \