"""
UMRT Rover Launch File
"""

"""
Imports
"""
import os
from launch import LaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument, RegisterEventHandler
from launch.substitutions import Command, FindExecutable, PathJoinSubstitution, LaunchConfiguration
from launch.conditions import IfCondition
from launch.event_handlers import OnProcessExit
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy, DurabilityPolicy 
from launch_ros.actions import Node

from ament_index_python.packages import get_package_share_directory
from launch_ros.substitutions import FindPackageShare
from launch_xml.launch_description_sources import XMLLaunchDescriptionSource


"""
Generate Launch Description
"""
def generate_launch_description():

    """
    Parameters
    """
    # Path to the drivetrain launch directory
    drivetrain_launch_dir = os.path.join(
        get_package_share_directory('umrt-arm-ros-firmware'), 'launch')
    
    # Path to the GPS launch directory
    gps_launch_dir = os.path.join(
        get_package_share_directory('umrt-localization-ros'), 'launch')
    
    """
    Launch Arguments
    """
    #   GUI
    gui_arg = DeclareLaunchArgument(
        "gui",
        default_value="True",
        description="Start RViz2 automatically with this launch file.",
    )
    
    #   Simulation or Real
    use_mock_hardware_arg = DeclareLaunchArgument(
        "use_mock_hardware",
        default_value="False",
        description="Start robot with mock hardware mirroring command to its states.",
    )

    #   CAN Interface
    can_interface_arg = DeclareLaunchArgument(
        "can_interface",
        default_value="can0",
        description="CAN interface to use (e.g., 'can0' for real hardware, 'vcan0' for virtual).",
    )

    #   ROS 2 J1939 Static Bridge name
    DeclareLaunchArgument(
        "device_name",
        default_value="umrt_ros_controller",
        description="Name for the device using the static bridge.",
    )

    """
    Variables
    """
    gui = LaunchConfiguration("gui")
    use_mock_hardware = LaunchConfiguration("use_mock_hardware")
    can_interface = LaunchConfiguration("can_interface")
    device_name = LaunchConfiguration("device_name")

    """
    Nodes
    """
    '''imu_node = Node(
        package='umrt-emb-imu-node',
        executable='umrt-emb-imu-node',
        name='imu',
        namespace='imu'
    )'''

    static_bridge_node = Node(
        package='ros2_j1939_babbler',
        executable='static_bridge',
        name='static_bridge',
        namespace='static_bridge',
        parameters = [{
            'device_name': device_name,
            'can_interface': can_interface,
            'device_ID': 0x80,
        }]
    )

    """
    External Launch Files
    """
    #   Launch the Drivetrain System:
    #       - ros2_j1939_babbler static_bridge
    #       - ros2_socketcan sender and receiver
    #       - drivetrain 
    drivetrain_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(drivetrain_launch_dir, 'rover_drivetrain.launch.py')
        ), 
        launch_arguments={
            'gui': gui, 
            'use_mock_hardware': use_mock_hardware, 
            'can_interface': can_interface
        }.items()
    )

    ros2_socket_launch = IncludeLaunchDescription(
        XMLLaunchDescriptionSource([
            PathJoinSubstitution([
                FindPackageShare('ros2_socketcan'),
                'launch',
                'socket_can_bridge.launch.xml'
            ])
        ]),
        launch_arguments={
            'interface': can_interface,
            'to_can_bus_topic': '/to_can_bus'
        }.items()
    )

    # Launch the GPS Nodes, and Heading Node 
    localization_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(gps_launch_dir, 'localization.launch.py')
        )
    )

    """
    Launch
    """
    rover = [
        gui_arg,
        use_mock_hardware_arg,
        can_interface_arg,
        device_name,
        ros2_socket_launch,
        drivetrain_launch,
        gps_launch,
        # imu_node,
        # localization_launch
    ]

    return LaunchDescription(rover)
