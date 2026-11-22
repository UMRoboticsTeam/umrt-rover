# --- Stage 1: Babbler Builder ---
FROM ros:humble-ros-base AS babblerbuilder

# Installing Packages
RUN echo '#!/bin/sh\nexit 0' > /usr/local/bin/systemctl && chmod +x /usr/local/bin/systemctl
    
RUN apt-get update && apt-get install -y --no-install-recommends \
    file \
    libboost-all-dev \
    python-is-python3 \
    python3-bloom \
    python3-curtsies \
    python3-doxypypy \
    python3-pip \
    ros-humble-can-msgs \
    ros-humble-ros-babel-fish
   
# These files are referenced in symlinks, so they also have to be copied.
RUN sudo pip3 install cantools
RUN mkdir -p /ws/src/ros2_j1939_babbler

# Build Babbler
COPY ./version /ws
COPY ./Messages.sym /ws
COPY src /ws/src/

RUN git clone https://github.com/UMRoboticsTeam/ros2_j1939_babbler.git /ws/src/ros2_j1939_babbler \
    && git -C /ws/src/ros2_j1939_babbler checkout v0.2.4
RUN cd /ws/src && ./build_scripts.sh

# --- Stage 2: Arm Firmware Builder ---
# Note this is to be removed once arm firmware is back up to date.
FROM ros:humble-ros-base AS armfirmwarebuilder

# Installing Packages
RUN echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/umrt.asc] https://raw.githubusercontent.com/UMRoboticsTeam/umrt-apt-repo/main/ humble main" > /etc/apt/sources.list.d/umrt_source.list \
    && echo '#!/bin/sh\nexit 0' > /usr/local/bin/systemctl && chmod +x /usr/local/bin/systemctl
    
RUN --mount=type=secret,id=apt_auth_conf,target=/etc/apt/auth.conf.d/umrt.conf \
    --mount=type=secret,id=apt_pubkey,target=/etc/apt/keyrings/umrt.asc,mode=0644 \
    apt-get update && apt-get install -y --no-install-recommends \
    file \
    libboost-all-dev \
    openframeworksarduino=0.0.3 \
    ros-humble-hardware-interface \
    ros-humble-pluginlib \
    ros-humble-realtime-tools \
    ros-humble-ros2-socketcan \
    umrt-arm-firmware-lib
    
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/share /opt/ros/humble/share
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/lib /opt/ros/humble/lib
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/include /opt/ros/humble/include
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/local/lib/python3.10/dist-packages /opt/ros/humble/local/lib/python3.10/dist-packages

SHELL ["/bin/bash", "-c"]

RUN mkdir -p /ws/src/arm-lib-firmware
RUN git clone https://github.com/UMRoboticsTeam/umrt-arm-ros-firmware.git /ws/src/arm-lib-firmware \
    && git -C /ws/src/arm-lib-firmware checkout wheel_controller

RUN cd /ws/src/arm-lib-firmware && \
    source /opt/ros/humble/setup.bash && \
    colcon build --event-handlers console_direct+ --merge-install --install-base ./build-output


# --- Stage 3: Final Image ---
FROM ros:humble-ros-base

ENV ROS_DOMAIN_ID=2
ENV ROS_LOCALHOST_ONLY=0
ENV RMW_IMPLEMENTATION="rmw_fastrtps_cpp" 
ENV BRIDGE_WORKSPACE="/workspace/umrt-zenoh-bridge"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV QT_X11_NO_MITSHM=1
ENV ROUTE_POLICY=drop-default

# Copying in babbler into build
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/share /opt/ros/humble/share
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/lib /opt/ros/humble/lib
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/include /opt/ros/humble/include
COPY --from=babblerbuilder /ws/src/ros2_j1939_babbler/build-output/local/lib/python3.10/dist-packages /opt/ros/humble/local/lib/python3.10/dist-packages

# Copying in from arm-lib into build
COPY --from=armfirmwarebuilder /ws/src/arm-lib-firmware/build-output/share /opt/ros/humble/share
COPY --from=armfirmwarebuilder /ws/src/arm-lib-firmware/build-output/lib /opt/ros/humble/lib
COPY --from=armfirmwarebuilder /ws/src/arm-lib-firmware/build-output/include /opt/ros/humble/include

# Public key has been downloaded using
#   curl -fsSL https://download.eclipse.org/zenoh/debian-repo/zenoh-public-key | gpg --dearmor --yes --output ./files/zenoh-public-key.gpg
# on October 31st, 2026
COPY ./files/zenoh-public-key.gpg /etc/apt/keyrings/zenoh-public-key.gpg

# Copy APT configuration files
COPY ./files/99parallel /etc/apt/apt.conf.d/99parallel

# Installing Packages
RUN echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/zenoh-public-key.gpg] https://download.eclipse.org/zenoh/debian-repo/ /" > /etc/apt/sources.list.d/zenoh.list \
    && echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/umrt.asc] https://raw.githubusercontent.com/UMRoboticsTeam/umrt-apt-repo/main/ humble main" > /etc/apt/sources.list.d/umrt_source.list \
    && echo '#!/bin/sh\nexit 0' > /usr/local/bin/systemctl && chmod +x /usr/local/bin/systemctl
    
RUN --mount=type=secret,id=apt_auth_conf,target=/etc/apt/auth.conf.d/umrt.conf \
    --mount=type=secret,id=apt_pubkey,target=/etc/apt/keyrings/umrt.asc,mode=0644 \
    rm -f /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-overwrite" \
        ffmpeg \
	iproute2 \
	iputils-ping \
	less \
	nano \
	ros-humble-depthai-bridge-v3 \
	ros-humble-depthai-ros-msgs-v3 \
	ros-humble-depthai-v3=3.10.0-1 \
	ros-humble-ffmpeg-image-transport \
	ros-humble-ffmpeg-image-transport-msgs \
	ros-humble-foxglove-compressed-video-transport \
	ros-humble-foxglove-msgs \
	ros-humble-image-transport \
	ros-humble-image-transport-plugins \
	ros-humble-joy \
	ros-humble-joy-teleop \
	ros-humble-network-bridge \
	ros-humble-ros-babel-fish \
	ros-humble-rviz2 \
	ros-humble-teleop-twist-joy \
	ros-humble-umrt-drivetrain-ros \
	ros-humble-umrt-emb-imu-ros \
	ros-humble-umrt-localization-ros \
	ros-humble-umrt-project-perry-description \
	ros-humble-umrt-ros-poe-cam \
	ros-humble-umrt-serial-cam-ros \
	ros-humble-usb-cam \
	ros-humble-vision-msgs \
	umrt-geiger-interface=0.1.2 \
	umrt-imu-interface \
	zenoh-bridge-ros2dds=1.3.4 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/apt/sources.list.d/umrt_source.list

# Copying in Launch Files and Entrypoint
COPY umrt_entrypoint.sh /umrt_entrypoint.sh
COPY ./launch /opt/ros/humble/share/launch
RUN chmod +x /umrt_entrypoint.sh
RUN ldconfig

ENTRYPOINT ["/umrt_entrypoint.sh"]
