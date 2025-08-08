"""
UMRT Rover Launch File
"""

"""
Imports
"""
from launch import LaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import IncludeLaunchDescription
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
    # Path to the drivetrain launch directory
    drivetrain_launch_dir = os.path.join(
        get_package_share_directory('umrt-drivetrain-ros'), 'launch')
    

    """
    Nodes
    """
    gps_node = Node(
        package='gpsx',
        executable='gps_node',
        name='gps',
        namespace='gps',
        parameters=[{
            'comm_port':"/dev/ttyUSB0",
            'comm_speed': 4800
        }]
    )

    imu_node = Node(
        package='umrt-emb-imu-node',
        executable='umrt-emb-imu-node',
        name='imu',
        namespace='imu'
    )

    """
    External Launch Files
    """
    drivetrain_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(drivetrain_launch_dir, 'diffbot.launch.py')
        )
    )

    """
    Launch
    """
    rover = [
        drivetrain_launch,
        imu_node,
        gps_node
    ]

    launch_entities = rover

    return LaunchDescription(launch_entities)