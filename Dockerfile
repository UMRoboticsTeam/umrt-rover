FROM ros:humble-ros-base

ENV ROS_DOMAIN_ID=2
ENV ROS_LOCALHOST_ONLY=0
ENV RMW_IMPLEMENTATION="rmw_fastrtps_cpp" 
ENV BRIDGE_WORKSPACE="/workspace/umrt-zenoh-bridge"
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV QT_X11_NO_MITSHM=1
ENV ROUTE_POLICY=drop-default

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.eclipse.org/zenoh/debian-repo/zenoh-public-key | gpg --dearmor --yes --output /etc/apt/keyrings/zenoh-public-key.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/zenoh-public-key.gpg] https://download.eclipse.org/zenoh/debian-repo/ /" > /etc/apt/sources.list.d/zenoh.list \
    && echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/umrt.asc] https://raw.githubusercontent.com/UMRoboticsTeam/umrt-apt-repo/main/ humble main" > /etc/apt/sources.list.d/umrt_source.list \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" > /etc/apt/sources.list.d/ros2.list \
    && echo '#!/bin/sh\nexit 0' > /usr/local/bin/systemctl && chmod +x /usr/local/bin/systemctl \
    && echo 'Acquire::Queue-Mode "host";' > /etc/apt/apt.conf.d/99parallel \
    && echo 'Acquire::http::Pipeline-Depth "5";' >> /etc/apt/apt.conf.d/99parallel

RUN --mount=type=secret,id=apt_auth_conf,target=/etc/apt/auth.conf.d/umrt.conf \
    --mount=type=secret,id=apt_pubkey,target=/etc/apt/keyrings/umrt.asc,mode=0644 \
    rm -f /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-overwrite" \
        less nano ffmpeg iputils-ping ros-humble-rviz2 ros-humble-umrt-arm-ros-firmware \
        umrt-geiger-interface=0.1.2 ros-humble-umrt-ros-poe-cam \ 
        ros-humble-umrt-serial-cam-ros ros-humble-umrt-project-perry-description \
        ros-humble-umrt-drivetrain-ros ros-humble-umrt-emb-imu-ros \
        zenoh-bridge-ros2dds=1.3.4 ros-humble-umrt-localization-ros \
        ros-humble-joy ros-humble-joy-teleop ros-humble-teleop-twist-joy \
        ros-humble-foxglove-msgs ros-humble-foxglove-compressed-video-transport \
        ros-humble-network-bridge ros-humble-usb-cam ros-humble-vision-msgs ros-humble-image-transport \
        ros-humble-image-transport-plugins ros-humble-ffmpeg-image-transport ros-humble-ffmpeg-image-transport-msgs \
        ros-humble-depthai-v3 ros-humble-depthai-ros-msgs-v3 ros-humble-depthai-bridge-v3 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/apt/sources.list.d/umrt_source.list

COPY umrt_entrypoint.sh /umrt_entrypoint.sh
COPY ./launch /opt/ros/humble/share/launch
RUN chmod +x /umrt_entrypoint.sh
RUN ldconfig

ENTRYPOINT ["/umrt_entrypoint.sh"]
