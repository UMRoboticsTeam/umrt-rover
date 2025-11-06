"""
UMRT Robot Cameras Launch

TO-DO:
- Work on QoS Profile for all cameras
- Define Launch Arguments for Cameras to keep a persistent way of getting /dev/video
"""

"""
Imports
"""
from launch import LaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy, DurabilityPolicy 
from launch_ros.actions import Node
import os
from ament_index_python.packages import get_package_share_directory  
        
"""
Generate Launch Description 
"""
def generate_launch_description():
        
    """
    Parameters
    """
    serial_cam_launch_dir = os.path.join(
            get_package_share_directory('umrt-serial-cam-ros'), 'launch'
    )

    poe_cam_launch_dir = os.path.join(
            get_package_share_directory('umrt-ros-poe-cam'), 'launch'
    )

    """
    External Launch Files
    """
    # Launch all Cameras
    
    poe_cam = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(poe_cam_launch_dir, 'mobile_publisher.launch.py')
        )
    )

    serial_cams = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(serial_cam_launch_dir, 'robot.launch.py')
        )
    )

    """
    Launch
    """
    all_cameras = [
        poe_cam,
        serial_cams
    ]

    launch_entities = all_cameras

    return LaunchDescription(launch_entities)