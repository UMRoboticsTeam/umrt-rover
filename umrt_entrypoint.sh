#!/bin/bash
RED_TXT="\033[31m"
RESET_TXT="\033[0m"


################################
# require_file
#   Looks to see if the required file is found on the device
#
# Author: Connor
# parameter: path - the path to the file
#
# returns: none
################################
require_file() {
  local path="$1"

  if [[ ! -f "${path}" ]]; then
    echo -e "[${RED_TXT}ERRO${RESET_TXT} - $(date +"%b %d %T")] Missing required file: ${path}" >&2
    c_exit
  fi
}

################################
# c_exit
#   a custom exit function that add the closing line to the function
#
# Author: Domenic Chao
# parameter: none
#
# returns: none
################################
c_exit() {
  echo -e "//*********************************************************//\n\n"
  sleep infinity 
  exit
}

################################
# main
#   The main section of code that runs everytime
#
# Author: Domenic Chao
# parameter: none
#
# returns: none
################################
main() {
  if [ -z "$CAN_INTERFACE" ]; then
    CAN_INTERFACE="can1"
  fi

  echo "//****************** UMRT ROVER LAUNCHER ******************//"
  echo "[INFO - $(date +"%b %d %T")] Starting UMRT Rover"

  echo "[INFO - $(date +"%b %d %T")] Sourcing ros_entrypoint.sh"
  source ./ros_entrypoint.sh

  if  [ "$BOOT_LO_NET" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Launching Zenoh Rover Low Network"
    require_file "${BRIDGE_WORKSPACE}/config/rover_lo.json"
    zenoh-bridge-ros2dds -c "${BRIDGE_WORKSPACE}/config/rover_lo.json" > /dev/null &
  fi

  if [ "$BOOT_HI_NET" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Launching Zenoh Rover High Network"
    require_file "${BRIDGE_WORKSPACE}/config/rover_hi.json"
    zenoh-bridge-ros2dds -c "${BRIDGE_WORKSPACE}/config/rover_hi.json" > /dev/null &
  fi
  
  if [ "$BOOT_HI_F_LO_NET" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Launching Zenoh Rover High Fail Low Network"
    require_file "${BRIDGE_WORKSPACE}/config/rover-hi_f_lo.json"
    zenoh-bridge-ros2dds -c "${BRIDGE_WORKSPACE}/config/rover-hi_f_lo.json" > /dev/null &
  fi
  
  if [ "$BOOT_LO_F_HI_NET" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Launching Zenoh Rover Low Fail High Network"
    require_file "${BRIDGE_WORKSPACE}/config/rover_lo_f_hi.json"
    zenoh-bridge-ros2dds -c "${BRIDGE_WORKSPACE}/config/rover_lo_f_hi.json" > /dev/null &
  fi
  
  if [ "$BOOT_LOC_NET" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Launching Zenoh Rover Local Network"
    require_file "${BRIDGE_WORKSPACE}/config/rover_loc.json"
    zenoh-bridge-ros2dds -c "${BRIDGE_WORKSPACE}/config/rover_loc.json" > /dev/null &
  fi
  
  if [ "$BOOT_ALL_NET" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Launching Zenoh Rover All Network"
    require_file "${BRIDGE_WORKSPACE}/config/rover_all.json"
    zenoh-bridge-ros2dds -c "${BRIDGE_WORKSPACE}/config/rover_all.json" > /dev/null &
  fi
  
  if [ "$BOOT_CAM" != "false" ]; then
    echo "[INFO - $(date +"%b %d %T")] Starting POE Cams"
    ros2 launch umrt-ros-poe-cam mobile_publisher.launch.py &
  fi

  if [ "$BOOT_DRIVETRAIN" != "false" ]; then
    while ! ip link show "$CAN_INTERFACE" 2>/dev/null | grep -q "<NOARP,UP,LOWER_UP[^>]*>"; do
      echo "Waiting for $CAN_INTERFACE"
      sleep 2
    done

    echo "[INFO - $(date +"%b %d %T")] Starting Drive Train"
    ros2 launch launch rover.launch.py &
  fi

  echo "[INFO - $(date +"%b %d %T")] Rover Launch Complete Successfully"
  c_exit
}

main
