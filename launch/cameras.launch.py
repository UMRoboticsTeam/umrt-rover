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
        
    #   Rover Cameras
    rover_cams_arg = DeclareLaunchArgument(
        "rover_cameras",
        default_value="True",
        description="Launch only the rover cameras.",
    )

    #   Arm Cameras
    arm_cams_arg = DeclareLaunchArgument(
        "robotic_arm_cameras",
        default_value="True",
        description="Launch only the robotic arm cameras.",
    )

    """
    Variables
    """
    rover_cams = LaunchConfiguration("rover_cameras")
    arm_cams = LaunchConfiguration("robotic_arm_cameras")

    """
    Directories
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
    # PoE Camera
    poe_cam = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(poe_cam_launch_dir, 'mobile_publisher.launch.py')
        )
    )
    compressed_conversion = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(poe_cam_launch_dir, 'transport.launch.py')
        )
    )

    # Serial Camera 
    serial_cams = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(serial_cam_launch_dir, 'camera.launch.py')
        )
    )

    """
    Launch
    """
    vision = [
        rover_cams_arg,
        arm_cams_arg,
        poe_cam,
        #compressed_conversion,
        serial_cams
    ]

    return LaunchDescription(vision)
