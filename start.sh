#!/bin/bash
set -euo pipefail

xhost +local:root > /dev/null 2>&1

CONFIG_DIR="./config"

################################
# check_dir
#   Check if the dir exists and creates it if it doesnt
#
# Author: Domenic Chao
# parameter: DIR - the path to the dir
#
# returns: none
################################
check_dir() {
	local DIR="$1"
	if [ ! -d "$DIR" ]; then
		echo "[INFO - $(date +"%b %d %T")] Directory $DIR does not exist. Creating new folder"
		mkdir -p "$DIR"
	fi
}

# Checking to make sure all the dirs exist
check_dir "$CONFIG_DIR"

# Exporting Variables
export RES_CONFIG_DIR=$(realpath "${CONFIG_DIR}")

# Starting Docker Container
docker compose -f "./compose-rover.yaml" up -d --force-recreate --renew-anon-volumes

sleep 2

PID=$(docker inspect -f '{{.State.Pid}}' bridge_rover 2>/dev/null)
while [ -z "$PID" ] || [ "$PID" -eq 0 ]; do
    sleep 1
    PID=$(docker inspect -f '{{.State.Pid}}' bridge_rover 2>/dev/null)
done

ip link set can1 down
ip link set can1 netns "$PID"

docker exec bridge_rover ip link set can1 up type can bitrate 500000

