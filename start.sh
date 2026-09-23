#!/bin/bash
set -euo pipefail

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

# Waiting for container to Start
sleep 2

PID=$(docker inspect -f '{{.State.Pid}}' bridge_rover 2>/dev/null)
while [ -z "$PID" ] || [ "$PID" -eq 0 ]; do
    sleep 1
    PID=$(docker inspect -f '{{.State.Pid}}' bridge_rover 2>/dev/null)
done

# Moving the can Network inside the container
IFACE=can1
TYPE=$(ip -d -j link show "$IFACE" | grep -o '"info_kind":"[^"]*"' | cut -d'"' -f4)

ip link set "$IFACE" down

ip link set "$IFACE" netns "$PID"

if [ "$TYPE" = "can" ]; then
	nsenter -t "$PID" -n ip link set "$IFACE" type can bitrate 500000
fi

nsenter -t "$PID" -n ip link set "$IFACE" up
