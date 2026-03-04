#!/usr/bin/env python3
"""
Pick & Load 데모 — Doosan M1013

시퀀스:
  1. Pick 위치 접근    (base +30°, 팔 전방)
  2. Pick 하강 (집기)
  3. Pick 상승
  4. Load 위치 이동    (base -45°, 반대편)
  5. Load 하강 (놓기)
  6. Load 상승
  7. Home 복귀         (all-zeros)

실행:
  ros2 launch dsr_bringup2 dsr_bringup2_gazebo_moveit.launch.py model:=m1013
  python3 /mnt/e/WorkSpace/robot-simulation-platform/robots/doosan-m1013/tasks/pick_and_load.py
"""
import math
import time
import rclpy
from rclpy.action import ActionClient
from rclpy.node import Node
from rclpy.parameter import Parameter
from moveit_msgs.action import MoveGroup
from moveit_msgs.msg import (
    MotionPlanRequest, Constraints, JointConstraint, PlanningOptions
)

# ── 태스크 정보 ──────────────────────────────────────
TASK_PURPOSE = '데모 시연용'       # 용도
TASK_DESC = 'Pick & Load 표준'    # 간단 설명

# ── 설정 ──────────────────────────────────────────
MOVE_GROUP_NS = '/sim'           # Gazebo+MoveIt2 네임스페이스
PLANNING_GROUP = 'manipulator'
VELOCITY_SCALE = 0.3
ACCEL_SCALE = 0.3
STEP_PAUSE = 1.0                 # 스텝 간 대기(초)

JOINT_NAMES = [
    'joint_1', 'joint_2', 'joint_3',
    'joint_4', 'joint_5', 'joint_6',
]

deg = math.radians

# ── 웨이포인트 정의 ──────────────────────────────────
WAYPOINTS = [
    ('Pick 위치 접근',    [deg(30),  deg(-20), deg(90),  0.0, deg(45), 0.0]),
    ('Pick 하강 (집기)',  [deg(30),  deg(-10), deg(100), 0.0, deg(35), 0.0]),
    ('Pick 상승',         [deg(30),  deg(-20), deg(90),  0.0, deg(45), 0.0]),
    ('Load 위치 이동',    [deg(-45), deg(-20), deg(90),  0.0, deg(45), 0.0]),
    ('Load 하강 (놓기)',  [deg(-45), deg(-10), deg(100), 0.0, deg(35), 0.0]),
    ('Load 상승',         [deg(-45), deg(-20), deg(90),  0.0, deg(45), 0.0]),
    ('Home 복귀',         [0.0,      0.0,      0.0,      0.0, 0.0,     0.0]),
]


class TaskRunner(Node):
    """MoveGroup 액션을 통해 관절 목표를 순차 실행"""

    def __init__(self):
        super().__init__(
            'task_runner',
            parameter_overrides=[
                Parameter('use_sim_time', Parameter.Type.BOOL, True),
            ],
        )
        action_topic = f'{MOVE_GROUP_NS}/move_action'
        self._client = ActionClient(self, MoveGroup, action_topic)
        self.get_logger().info(f'Action topic: {action_topic}')

    def move_to(self, joint_values, description):
        """관절 목표로 Plan & Execute. 성공 여부 반환."""
        self.get_logger().info(f'>>> {description}')
        self.get_logger().info(
            f'    joints(deg): {[round(math.degrees(v), 1) for v in joint_values]}'
        )

        goal = MoveGroup.Goal()
        req = MotionPlanRequest()
        req.group_name = PLANNING_GROUP
        req.num_planning_attempts = 10
        req.allowed_planning_time = 5.0
        req.max_velocity_scaling_factor = VELOCITY_SCALE
        req.max_acceleration_scaling_factor = ACCEL_SCALE

        constraints = Constraints()
        for name, val in zip(JOINT_NAMES, joint_values):
            jc = JointConstraint()
            jc.joint_name = name
            jc.position = val
            jc.tolerance_above = 0.01
            jc.tolerance_below = 0.01
            jc.weight = 1.0
            constraints.joint_constraints.append(jc)
        req.goal_constraints = [constraints]

        goal.request = req
        goal.planning_options = PlanningOptions()
        goal.planning_options.plan_only = False
        goal.planning_options.replan = True
        goal.planning_options.replan_attempts = 3

        if not self._client.wait_for_server(timeout_sec=10.0):
            self.get_logger().error('MoveGroup 액션 서버 연결 실패')
            return False

        future = self._client.send_goal_async(goal)
        rclpy.spin_until_future_complete(self, future)
        handle = future.result()
        if not handle.accepted:
            self.get_logger().error(f'REJECTED: {description}')
            return False

        result_future = handle.get_result_async()
        rclpy.spin_until_future_complete(self, result_future)
        result = result_future.result()

        if result.status == 4:  # SUCCEEDED
            self.get_logger().info(f'OK: {description}')
            return True
        else:
            self.get_logger().error(
                f'FAIL: {description} (status={result.status}, '
                f'error={result.result.error_code.val})'
            )
            return False

    def run_sequence(self, waypoints):
        """웨이포인트 리스트를 순차 실행"""
        total = len(waypoints)
        self.get_logger().info('=' * 50)
        self.get_logger().info(f'  Task Start — {total} steps')
        self.get_logger().info('=' * 50)

        for i, (desc, joints) in enumerate(waypoints):
            label = f'{i + 1}/{total}  {desc}'
            if not self.move_to(joints, label):
                self.get_logger().error(f'스텝 {i + 1}에서 실패. 중단.')
                return False
            time.sleep(STEP_PAUSE)

        self.get_logger().info('=' * 50)
        self.get_logger().info('  Task Complete')
        self.get_logger().info('=' * 50)
        return True


def main():
    rclpy.init()
    node = TaskRunner()
    try:
        node.run_sequence(WAYPOINTS)
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
