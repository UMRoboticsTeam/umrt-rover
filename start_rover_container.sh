#!/usr/bin/env bash
xhost +local:docker

docker run \
	-it \
	-e DISPLAY \
	-e QT_X11_NO_MITSHM=1 \
	-e ROS_DOMAIN_ID=8 \
	--privileged \
	--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
	--volume="$(pwd):/workspace" \
	--volume="/tmp/.X11-unix/:/tmp/.X11-unix" \
	--volume="/dev:/dev" \
	--device-cgroup-rule="c 189:* rw" \
	--device /dev/dri \
	--device /dev/input \
	--rm \
	--network=host \
	--pid=host \
	--name umrt-rover \
	--pull=always \
	-v $ROS_WORKSPACE/umrt-rover/fastdds_profiles/fastdds_LoBW.xml:/fastdds_LoBW.xml:ro \
  	-e RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
  	-e FASTRTPS_DEFAULT_PROFILES_FILE=/fastdds_LoBW.xml \
	ghcr.io/umroboticsteam/umrt-rover:main \