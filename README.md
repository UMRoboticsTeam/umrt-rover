# UMRT Rover Image

99-camera-usb-name.rules -> Should be placed in /etc/udev/rules

set_cam_fps.sh -> Should be placed in /usr/local/bin/set_cam_fps.sh

start_rover_container.sh will pull this Dockerfile Image 

There should be 3 Containers hence 3 SSH
1. 900 MHz - Drivetrain, IMU
2. 2.4 GHz Cameras - Serial Camera and PoE Camera 
3. 900 MHz - Geiger Counter (For 2 Tasks)