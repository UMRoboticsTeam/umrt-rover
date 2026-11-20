#!/bin/bash

PID=$(docker inspect -f '{{.State.Pid}}' rover)

sudo ip link set can1 down
sudo ip link set can1 netns "$PID"

docker exec rover ip link set can1 up type can bitrate 500000
