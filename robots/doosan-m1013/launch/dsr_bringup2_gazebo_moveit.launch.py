#
#  dsr_bringup2 - Gazebo + MoveIt2 integrated launch
#
#  Gazebo Fortress gz_ros2_control as the sole controller_manager.
#  MoveIt2 controls the robot through Gazebo physics directly.
#  No DRCF emulator needed - IgnitionSystem is the hardware interface.
#

import os

from launch import LaunchDescription
from launch.actions import (
    DeclareLaunchArgument,
    IncludeLaunchDescription,
    RegisterEventHandler,
    TimerAction,
)
from launch.event_handlers import OnProcessExit
from launch.substitutions import (
    Command,
    FindExecutable,
    PathJoinSubstitution,
    LaunchConfiguration,
)
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.actions import OpaqueFunction
from ament_index_python.packages import get_package_share_directory
from moveit_configs_utils import MoveItConfigsBuilder
from dsr_bringup2.utils import show_git_info


# gz_ros2_control + MoveIt2 + RViz2 all share the same namespace
GZ_NS = "sim"


def moveit_nodes_function(context):
    model_value = LaunchConfiguration("model").perform(context)
    package_name_str = f"dsr_moveit_config_{model_value}"

    moveit_config = (
        MoveItConfigsBuilder(model_value, "robot_description", package_name_str)
        .robot_description(file_path=f"config/{model_value}.urdf.xacro")
        .robot_description_semantic(file_path="config/dsr.srdf")
        .trajectory_execution(file_path="config/moveit_controllers.yaml")
        .planning_pipelines(
            pipelines=["ompl", "chomp", "pilz_industrial_motion_planner"],
            default_planning_pipeline="ompl",
            load_all=False,
        )
        .to_moveit_configs()
    )

    # move_group in same namespace as gz_ros2_control
    run_move_group_node = Node(
        package="moveit_ros_move_group",
        executable="move_group",
        namespace=GZ_NS,
        output="screen",
        parameters=[
            moveit_config.to_dict(),
            {"use_sim_time": True},
        ],
    )

    # Patch RViz config to use GZ_NS namespace for move_group connection
    rviz_base = os.path.join(
        get_package_share_directory(package_name_str), "launch"
    )
    rviz_orig_config = os.path.join(rviz_base, "moveit.rviz")

    import tempfile
    with open(rviz_orig_config, 'r') as f:
        rviz_content = f.read()
    ns_prefix = "/" + GZ_NS
    rviz_content = rviz_content.replace(
        'Move Group Namespace: ""', f'Move Group Namespace: "{ns_prefix}"'
    )
    rviz_content = rviz_content.replace(
        'Planning Scene Topic: /monitored_planning_scene',
        f'Planning Scene Topic: {ns_prefix}/monitored_planning_scene',
    )
    rviz_content = rviz_content.replace(
        'Trajectory Topic: /display_planned_path',
        f'Trajectory Topic: {ns_prefix}/display_planned_path',
    )
    # Trajectory animation: slow down so it's visible, enable loop
    rviz_content = rviz_content.replace(
        'State Display Time: 0.05 s', 'State Display Time: 0.5 s'
    )
    rviz_content = rviz_content.replace(
        'State Display Time: 3x', 'State Display Time: 1x'
    )
    rviz_content = rviz_content.replace(
        'Loop Animation: false', 'Loop Animation: false'
    )

    patched_rviz = tempfile.NamedTemporaryFile(
        mode='w', suffix='.rviz', prefix='moveit_gz_', delete=False
    )
    patched_rviz.write(rviz_content)
    patched_rviz.close()

    rviz_node = Node(
        package="rviz2",
        executable="rviz2",
        name="rviz2",
        namespace=GZ_NS,
        output="log",
        arguments=["-d", patched_rviz.name],
        parameters=[
            moveit_config.robot_description,
            moveit_config.robot_description_semantic,
            moveit_config.planning_pipelines,
            moveit_config.robot_description_kinematics,
            moveit_config.joint_limits,
            {"use_sim_time": True},
        ],
    )

    return [run_move_group_node, rviz_node]


def generate_launch_description():
    show_git_info()

    ARGUMENTS = [
        DeclareLaunchArgument("model", default_value="m1013",
                              description="ROBOT_MODEL"),
        DeclareLaunchArgument("color", default_value="white",
                              description="ROBOT_COLOR"),
        DeclareLaunchArgument("x", default_value="0",
                              description="Spawn X position"),
        DeclareLaunchArgument("y", default_value="0",
                              description="Spawn Y position"),
        DeclareLaunchArgument("z", default_value="0",
                              description="Spawn Z position"),
        DeclareLaunchArgument("R", default_value="0",
                              description="Spawn Roll"),
        DeclareLaunchArgument("P", default_value="0",
                              description="Spawn Pitch"),
        DeclareLaunchArgument("Y", default_value="0",
                              description="Spawn Yaw"),
    ]

    # 1. URDF (use_gazebo=true, namespace=sim for gz_ros2_control)
    robot_description_content = Command([
        PathJoinSubstitution([FindExecutable(name="xacro")]),
        " ",
        PathJoinSubstitution([
            FindPackageShare("dsr_description2"),
            "xacro",
            LaunchConfiguration("model"),
        ]),
        ".urdf.xacro",
        " use_gazebo:=true",
        " color:=", LaunchConfiguration("color"),
        " namespace:=" + GZ_NS,
    ])

    # 2. Gazebo Fortress
    gazebo = IncludeLaunchDescription(
        PythonLaunchDescriptionSource([
            FindPackageShare("ros_gz_sim"),
            "/launch/gz_sim.launch.py",
        ]),
        launch_arguments={"gz_args": f" -r -v 3 {os.path.join(get_package_share_directory('dsr_bringup2'), 'worlds', 'm1013_moveit.sdf')}"}.items(),
    )

    # 3. Robot State Publisher (same namespace as gz_ros2_control)
    robot_state_pub_node = Node(
        package="robot_state_publisher",
        executable="robot_state_publisher",
        namespace=GZ_NS,
        output="screen",
        parameters=[
            {"robot_description": robot_description_content},
            {"use_sim_time": True},
        ],
    )

    # 4. Spawn robot in Gazebo
    gz_spawn_entity = Node(
        package="ros_gz_sim",
        executable="create",
        namespace=GZ_NS,
        output="screen",
        arguments=[
            "-topic", "robot_description",
            "-name", LaunchConfiguration("model"),
            "-allow_renaming", "true",
            "-x", LaunchConfiguration("x"),
            "-y", LaunchConfiguration("y"),
            "-z", LaunchConfiguration("z"),
            "-R", LaunchConfiguration("R"),
            "-P", LaunchConfiguration("P"),
            "-Y", LaunchConfiguration("Y"),
        ],
    )

    # 4b. Bridge Gazebo clock to ROS2 /clock (required for use_sim_time)
    gz_clock_bridge = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        output='screen',
        arguments=['/clock@rosgraph_msgs/msg/Clock[ignition.msgs.Clock'],
    )

    # 5. joint_state_broadcaster (same namespace)
    joint_state_broadcaster_spawner = Node(
        package="controller_manager",
        executable="spawner",
        namespace=GZ_NS,
        arguments=[
            "joint_state_broadcaster",
            "--controller-manager", "controller_manager",
            "--controller-manager-timeout", "120",
        ],
        parameters=[{"use_sim_time": True}],
    )

    # 6. dsr_moveit_controller (JointTrajectoryController)
    dsr_moveit_controller_spawner = Node(
        package="controller_manager",
        executable="spawner",
        namespace=GZ_NS,
        arguments=[
            "dsr_moveit_controller",
            "--controller-manager", "controller_manager",
            "--controller-manager-timeout", "120",
        ],
        parameters=[{"use_sim_time": True}],
    )

    # 7. MoveIt2 + RViz2
    moveit_nodes = OpaqueFunction(function=moveit_nodes_function)

    # Execution chain
    delay_jsb_spawner = TimerAction(
        period=5.0,
        actions=[joint_state_broadcaster_spawner],
    )

    delay_moveit_controller_after_jsb = RegisterEventHandler(
        OnProcessExit(
            target_action=joint_state_broadcaster_spawner,
            on_exit=[dsr_moveit_controller_spawner],
        )
    )

    delay_moveit_after_controller = RegisterEventHandler(
        OnProcessExit(
            target_action=dsr_moveit_controller_spawner,
            on_exit=[moveit_nodes],
        )
    )

    nodes = [
        gazebo,
        gz_clock_bridge,
        robot_state_pub_node,
        gz_spawn_entity,
        delay_jsb_spawner,
        delay_moveit_controller_after_jsb,
        delay_moveit_after_controller,
    ]

    return LaunchDescription(ARGUMENTS + nodes)
