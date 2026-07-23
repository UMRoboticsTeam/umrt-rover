# UMRT Rover Image

## TO-DO: 
- Have the Dockerfile be part of the build system, something like CI-CD 
- 

### Configuring Serial Camera Names and SYMLINK

The following ruleset, 99-camera-usb-names.rules, is used to uniquely identify the different serial 
cameras, this is because the serial cameras we use are the same, and there only difference when we 
plug them into the device is the USB dev-path. 

The script should be placed in: **/etc/udev/rules**

To ensure the rules are applied when the cameras are plugged in, the following terminal commands should be rand:

```shell
    sudo udevadm control --reload-rules
    sudo udevadm trigger 
```

### Configuring Serial Camera FPS

The following script, set_cam_fps.sh, is used to set the serial camera FPS once it is connected.
This script was initially used to limit FPS and reduce USB bandwidth, but with the introduction 
of multiple controller USB this is deemed unnecessary but will still be kept here. 

The script should be placed in: **/usr/local/bin/**

To ensure it becomes an executable, the following terminal commands should be ran: 

```shell
    sudo chmod +x /usr/local/bin/set_cam_fps.sh 
```

## Containers 

The Rover should run two containers, one specifically for the cameras, and the rest is for the rover. We do this because we have two radios, 2.4 GHz and 900 MHz. The 2.4 GHz radio will handle all the cameras, or high bandwidth data, while the 900 MHz will handle all the 

1. 2.4 GHz - Cameras: Serial Camera and PoE Camera
2. 900 MHz - Rover: Drivetrain, IMU, GPS

We run the following two containers via the two start container scripts:

1. **start_camera_container.sh**
2. **start_rover_container.sh**

To ensure they become executables, the following terminal commands should be ran: 

```shell
    sudo chmod +x start_camera_container.sh
    sudo chmod +x start_rover_container.sh
```

Running the scripts as terminal commands:

```shell
    ./start_camera_container
    ./start_rover_container
```

When inside the container, run the launch scripts, which should be volumed in, using the following commands:

```shell
    ros2 launch /launch/rover.launch.py
    ros2 launch /launch/cameras.launch.p
```














This repository contains a Docker image used to run the University of Manitoba Robotics Team's base station. This image is intended to only include runtime dependencies and software used as part of the base station team's workflow.

## How to use - (Apply to Rover - if it has Wi-Fi access)

1. Generate a *Personal Access Token* for your GitHub account
    1. In the upper-right corner of any page on GitHub, click your profile photo, then click `Settings`
    2. In the left sidebar, click `Developer settings`
    3. In the left sidebar, under `Personal access tokens`, click `Tokens (classic)`
    4. Click `Generate new token (classic)` at the top of the page
        1. Give your token a nice name, e.g. "UMRT Docker auth token"
        2. Set expiration to a reasonable date sometime between now and your expected graduation
        3. Check `read:packages`, and leave the rest unchecked
        4. Click Generate token
    5. You should now see a bunch of letters/numbers starting with `ghp_`, this is your token
    6. Save the token somewhere safe, once you leave this page you will never be able to see it again
2. Set up Docker authentication
    1. Open a terminal and type, `docker login ghcr.io`
    2. Enter your GitHub username, and instead of password paste your token
    3. You should now be able to download UMRT Docker images!
3. Test by running `docker pull ghcr.io/umroboticsteam/umrt-build` to download the latest image

## Launching the image
An example command is: 
`docker run --rm -it --name umrt-rover --pull=always ghcr.io/umroboticsteam/umrt-rover:main`
This always checks for and downloads the latest image before starting, which may or may not be the ideal behaviour.
If a specific version is wanted, such as `v0.0.1`, simply change `umrt-rover:main` to `umrt-rover:v0.0.1`.