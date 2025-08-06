FROM ros:humble-ros-base

RUN echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/umrt.asc] https://raw.githubusercontent.com/UMRoboticsTeam/umrt-apt-repo/main/ humble main" > /etc/apt/sources.list.d/umrt_source.list

RUN --mount=type=secret,id=apt_auth_conf,target=/etc/apt/auth.conf.d/umrt.conf --mount=type=secret,id=apt_pubkey,target=/etc/apt/keyrings/umrt.asc,mode=0644 \
    sudo apt update && sudo apt install -y \
        less \
        nano \
        umrt-geiger-interface=0.1.2 \
        ros-humble-rviz2 \
        ros-humble-umrt-ros-poe-cam=1.0.1-0jammy \
        ros-humble-umrt-project-perry-description=0.0.6-0jammy \
        ros-humble-umrt-drivetrain-ros=0.1.2-0jammy \
        ros-humble-umrt-emb-imu-ros=0.0.4-0jammy \
    && rm -rf /var/lib/apt/lists/*

RUN sudo rm -f /etc/apt/sources.list.d/umrt_source.list