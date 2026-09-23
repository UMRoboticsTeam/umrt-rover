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
    
    gps_launch_dir = get_package_share_directory('umrt-localization-ros')
    
    """
    Nodes
    """
    
    gps_launch_path = os.path.join(
        gps_launch_dir,
        'launch',
        'gps.launch.py'
    )

    # Both GPS, exactly as started by gps.launch.py.
    gps = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(gps_launch_path)
    )

    # heading_node, listening to the starboard's RELPOSNED topic.
    heading_node = Node(
        package='umrt-localization-ros',
        executable='heading_node',
        name='heading_node',
        parameters=[{'relpos_topic': '/gps_starboard/ubx_nav_rel_pos_ned'}]
    )
    
    imu_node = Node(
        package='umrt-emb-imu-ros',
        executable='umrt-emb-imu-ros',
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
        gps,
        heading_node,
    ]

    launch_entities = rover

    return LaunchDescription(launch_entities)
