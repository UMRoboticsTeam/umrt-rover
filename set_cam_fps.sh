#!/bin/bash

# Wait for the device node to be ready
sleep 1

# Set FPS on the correct video device
v4l2-ctl -d "$1" --set-parm="$2"

