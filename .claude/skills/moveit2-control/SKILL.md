---
name: moveit2-control
description: "MoveIt2 로봇 제어. 모션 플래닝, 로봇 이동, 포즈 제어, 관절 제어, 경로 계획, 웨이포인트"
---

# MoveIt2 로봇 제어

## 개요

MoveIt2를 통해 로봇을 제어하는 스킬.
사용자가 목표 조건(포즈, 관절 각도, 경로 등)을 주면 Claude가 Python 스크립트를 생성하고 WSL2에서 실행한다.

**전제 조건**: 시뮬레이션이 실행 중이어야 한다 (MoveIt2 모드 또는 Gazebo+MoveIt2).
미실행 시 → `/simulation-launch` 먼저 실행.

---

## 제어 유형

| 유형 | 설명 | 입력 형식 | 예시 |
|------|------|-----------|------|
| 목표 포즈 | TCP 위치+자세 이동 | x, y, z, rx, ry, rz | `x=0.3 y=0.2 z=0.5 rx=0 ry=180 rz=0` |
| 관절 각도 | 각 관절 직접 지정 | j1~j6 (deg) | `j1=0 j2=-90 j3=90 j4=0 j5=90 j6=0` |
| 이름 포즈 | 사전 정의 포즈 | 포즈 이름 | `home`, `ready`, `zero` |
| 직선 이동 | TCP 직선 경로 (LIN) | 목표 포즈 | `x=0.3 y=0 z=0.5 planner=pilz_lin` |
| 원호 이동 | TCP 원호 경로 (CIRC) | 경유점 + 목표점 | Pilz CIRC 사용 |
| 경유점 경로 | 여러 점 순차 이동 | 포즈 목록 | 웨이포인트 배열 |

---

## 조건 입력 가이드

사용자는 아래 형식으로 조건을 입력한다. Claude가 파싱하여 코드를 생성한다.

### 1. 목표 포즈 (Cartesian)

```
x=0.3 y=0.0 z=0.5 rx=0 ry=180 rz=0
```

- 위치: m 단위 (x, y, z) — 로봇 base_link 기준
- 자세: 도(°) 단위 (rx, ry, rz — Roll/Pitch/Yaw)
- 생략된 자세는 현재 자세 유지

### 2. 관절 각도 (Joint)

```
j1=0 j2=-45 j3=90 j4=0 j5=45 j6=0
```

- 각도: 도(°) 단위
- M1013 관절 범위:

| 관절 | 범위 | 최대 속도 | 최대 토크 |
|------|------|-----------|-----------|
| J1 | ±360° | 120°/s | 346 Nm |
| J2 | ±360° | 120°/s | 346 Nm |
| J3 | ±160° | 180°/s | 163 Nm |
| J4 | ±360° | 225°/s | 50 Nm |
| J5 | ±360° | 225°/s | 50 Nm |
| J6 | ±360° | 225°/s | 50 Nm |

### 3. 이름 포즈

```
home
```

사전 정의된 포즈:

| 포즈명 | J1 | J2 | J3 | J4 | J5 | J6 | 설명 |
|--------|----|----|----|----|----|----|------|
| zero | 0° | 0° | 0° | 0° | 0° | 0° | 모든 관절 0도 |
| home | 0° | 0° | 90° | 0° | 90° | 0° | 작업 시작 자세 |

### 4. 속도/가속도 (선택)

```
speed=0.3 accel=0.3
```

- 0.0~1.0 비율 (기본값: 0.1)
- 협동로봇 안전 속도: TCP 0.25 m/s 이하 권장
- speed=1.0일 때 M1013 최대 TCP 속도: 1.0 m/s

### 5. 플래너 (선택)

```
planner=ompl
```

| 플래너 | 값 | 사용 시점 | 특징 |
|--------|-----|-----------|------|
| OMPL | `ompl` | 장애물 환경, 복잡한 경로 | 범용, 확률 기반, 기본값 |
| Pilz PTP | `pilz_ptp` | 단순 이동, 반복 작업 | 결정론적, 최단 관절 경로 |
| Pilz LIN | `pilz_lin` | 직선 접근/후퇴 | TCP 직선 경로 보장 |
| Pilz CIRC | `pilz_circ` | 원호 동작 (용접, 도포) | 원형 경로 보장 |
| CHOMP | `chomp` | 장애물 근접 경로 최적화 | 매끄러운 경로 |

### 6. 입력 예시 모음

```
# 포즈 이동 (기본 OMPL)
x=0.3 y=0.0 z=0.5

# 포즈 이동 + 자세 + 속도
x=0.3 y=0.0 z=0.5 rx=0 ry=180 rz=0 speed=0.2

# 관절 이동
j1=0 j2=-45 j3=90 j4=0 j5=45 j6=0

# 이름 포즈 (빠르게)
home speed=0.5

# 직선 이동 (Pilz LIN)
x=0.3 y=0.0 z=0.3 planner=pilz_lin speed=0.1

# 여러 경유점 (순차 이동)
waypoints:
  - x=0.3 y=0.0 z=0.5
  - x=0.3 y=0.2 z=0.5
  - x=0.3 y=0.2 z=0.3
```

---

## 실행 워크플로우

Claude는 아래 순서로 실행한다:

### 1. 시뮬레이션 상태 확인

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && ros2 node list 2>/dev/null | grep -q move_group && echo MOVEIT_OK || echo MOVEIT_NOT_RUNNING"
```

미실행 시 `/simulation-launch`로 안내.

### 2. 현재 상태 조회

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && ros2 topic echo /joint_states --once"
```

### 3. Python 스크립트 생성 → /tmp/moveit2_scripts/ 에 저장

### 4. 실행

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && python3 /tmp/moveit2_scripts/{script}.py"
```

### 5. 결과 확인

실행 후 관절 상태를 조회하고 사용자에게 보고한다.

> **핵심 사항 (실전 검증 완료)**:
> - Planning Group 이름: **`manipulator`** (SRDF 기준, `arm`이 아님)
> - 관절 이름: **`joint_1` ~ `joint_6`** (언더스코어 포함)
> - 실행 방법: `/execute_trajectory` 대신 **`/dsr_moveit_controller/follow_joint_trajectory`** 사용
> - 워크플로우: Plan(`/plan_kinematic_path`) → Execute(`FollowJointTrajectory`) 분리

---

## Python 코드 템플릿 (실전 검증 완료)

> **공통 패턴**: Plan(`/plan_kinematic_path`) → Execute(`/dsr_moveit_controller/follow_joint_trajectory`)
> MoveIt2의 `/execute_trajectory`는 Doosan 드라이버와 충돌하므로 FollowJointTrajectory를 직접 사용한다.

### 관절 각도 이동

```python
#!/usr/bin/env python3
"""MoveIt2 관절 각도 이동 — Plan + FollowJointTrajectory"""
import rclpy
from rclpy.node import Node
from moveit_msgs.srv import GetMotionPlan
from control_msgs.action import FollowJointTrajectory
from moveit_msgs.msg import Constraints, JointConstraint
from rclpy.action import ActionClient
import math, sys

class MoveToJoints(Node):
    def __init__(self):
        super().__init__('moveit2_joint_move')
        self._plan_client = self.create_client(GetMotionPlan, '/plan_kinematic_path')
        self._exec_client = ActionClient(self, FollowJointTrajectory,
            '/dsr_moveit_controller/follow_joint_trajectory')
        self.get_logger().info('서비스/액션 연결 대기...')
        self._plan_client.wait_for_service(timeout_sec=10.0)
        self._exec_client.wait_for_server(timeout_sec=10.0)
        self.get_logger().info('연결 완료')

    def move(self, joints_deg, speed=0.1, accel=0.1, planner='ompl'):
        joint_names = ['joint_1','joint_2','joint_3','joint_4','joint_5','joint_6']
        joints_rad = [math.radians(j) for j in joints_deg]

        req = GetMotionPlan.Request()
        mp = req.motion_plan_request
        mp.group_name = 'manipulator'
        mp.max_velocity_scaling_factor = speed
        mp.max_acceleration_scaling_factor = accel
        mp.num_planning_attempts = 10
        mp.allowed_planning_time = 5.0

        # 플래너 설정
        if planner == 'pilz_ptp':
            mp.pipeline_id = 'pilz_industrial_motion_planner'
            mp.planner_id = 'PTP'
        elif planner == 'pilz_lin':
            mp.pipeline_id = 'pilz_industrial_motion_planner'
            mp.planner_id = 'LIN'
        elif planner == 'chomp':
            mp.pipeline_id = 'chomp'
            mp.planner_id = ''
        else:
            mp.pipeline_id = 'ompl'
            mp.planner_id = 'RRTConnectkConfigDefault'

        constraints = Constraints()
        for name, value in zip(joint_names, joints_rad):
            jc = JointConstraint()
            jc.joint_name = name
            jc.position = value
            jc.tolerance_above = 0.01
            jc.tolerance_below = 0.01
            jc.weight = 1.0
            constraints.joint_constraints.append(jc)
        mp.goal_constraints.append(constraints)

        degs = [f'{d:.1f}' for d in joints_deg]
        self.get_logger().info(f'목표 (deg): {degs}')
        self.get_logger().info('경로 계획 중...')

        future = self._plan_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        response = future.result()

        if response.motion_plan_response.error_code.val != 1:
            self.get_logger().error(f'계획 실패 (에러: {response.motion_plan_response.error_code.val})')
            return False

        traj = response.motion_plan_response.trajectory
        points = len(traj.joint_trajectory.points)
        self.get_logger().info(f'계획 성공! 웨이포인트: {points}개')

        # FollowJointTrajectory로 실행
        self.get_logger().info('실행 중...')
        goal = FollowJointTrajectory.Goal()
        goal.trajectory = traj.joint_trajectory

        future = self._exec_client.send_goal_async(goal)
        rclpy.spin_until_future_complete(self, future)
        goal_handle = future.result()
        if not goal_handle.accepted:
            self.get_logger().error('실행 거부됨')
            return False

        result_future = goal_handle.get_result_async()
        rclpy.spin_until_future_complete(self, result_future)
        result = result_future.result().result
        if result.error_code == 0:
            self.get_logger().info('이동 완료!')
            return True
        else:
            self.get_logger().error(f'실행 실패 (에러: {result.error_code})')
            return False

def main():
    rclpy.init()
    node = MoveToJoints()
    # ▼ 여기에 관절 각도 입력 (도 단위) ▼
    node.move([0.0, 0.0, 90.0, 0.0, 90.0, 0.0], speed=0.1)  # home 포즈
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

### 포즈 이동 (Cartesian 목표)

```python
#!/usr/bin/env python3
"""MoveIt2 포즈 이동 — Plan + FollowJointTrajectory"""
import rclpy
from rclpy.node import Node
from moveit_msgs.srv import GetMotionPlan
from control_msgs.action import FollowJointTrajectory
from moveit_msgs.msg import (
    Constraints, PositionConstraint, OrientationConstraint, BoundingVolume
)
from geometry_msgs.msg import Pose
from shape_msgs.msg import SolidPrimitive
from rclpy.action import ActionClient
import math, sys

class MoveToPose(Node):
    def __init__(self):
        super().__init__('moveit2_pose_move')
        self._plan_client = self.create_client(GetMotionPlan, '/plan_kinematic_path')
        self._exec_client = ActionClient(self, FollowJointTrajectory,
            '/dsr_moveit_controller/follow_joint_trajectory')
        self._plan_client.wait_for_service(timeout_sec=10.0)
        self._exec_client.wait_for_server(timeout_sec=10.0)

    def move(self, x, y, z, rx=0.0, ry=0.0, rz=0.0, speed=0.1, accel=0.1, planner='ompl'):
        qx, qy, qz, qw = self._rpy_to_quat(math.radians(rx), math.radians(ry), math.radians(rz))

        req = GetMotionPlan.Request()
        mp = req.motion_plan_request
        mp.group_name = 'manipulator'
        mp.max_velocity_scaling_factor = speed
        mp.max_acceleration_scaling_factor = accel
        mp.num_planning_attempts = 10
        mp.allowed_planning_time = 5.0
        mp.pipeline_id = 'ompl'
        mp.planner_id = 'RRTConnectkConfigDefault'

        target = Pose()
        target.position.x, target.position.y, target.position.z = x, y, z
        target.orientation.x, target.orientation.y = qx, qy
        target.orientation.z, target.orientation.w = qz, qw

        # Position Constraint
        pc = PositionConstraint()
        pc.header.frame_id = 'base_link'
        pc.link_name = 'link_6'
        bv = BoundingVolume()
        sp = SolidPrimitive()
        sp.type = SolidPrimitive.SPHERE
        sp.dimensions = [0.01]
        bv.primitives.append(sp)
        bv.primitive_poses.append(target)
        pc.constraint_region = bv
        pc.weight = 1.0

        # Orientation Constraint
        oc = OrientationConstraint()
        oc.header.frame_id = 'base_link'
        oc.link_name = 'link_6'
        oc.orientation = target.orientation
        oc.absolute_x_axis_tolerance = 0.01
        oc.absolute_y_axis_tolerance = 0.01
        oc.absolute_z_axis_tolerance = 0.01
        oc.weight = 1.0

        constraints = Constraints()
        constraints.position_constraints.append(pc)
        constraints.orientation_constraints.append(oc)
        mp.goal_constraints.append(constraints)

        self.get_logger().info(f'목표: x={x:.3f} y={y:.3f} z={z:.3f} rx={rx:.0f} ry={ry:.0f} rz={rz:.0f}')

        future = self._plan_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        resp = future.result()
        if resp.motion_plan_response.error_code.val != 1:
            self.get_logger().error(f'계획 실패 (에러: {resp.motion_plan_response.error_code.val})')
            return False

        traj = resp.motion_plan_response.trajectory
        self.get_logger().info(f'계획 성공! 웨이포인트: {len(traj.joint_trajectory.points)}개')

        goal = FollowJointTrajectory.Goal()
        goal.trajectory = traj.joint_trajectory
        future = self._exec_client.send_goal_async(goal)
        rclpy.spin_until_future_complete(self, future)
        result_future = future.result().get_result_async()
        rclpy.spin_until_future_complete(self, result_future)

        if result_future.result().result.error_code == 0:
            self.get_logger().info('이동 완료!')
            return True
        self.get_logger().error('실행 실패')
        return False

    def _rpy_to_quat(self, r, p, y):
        cr, sr = math.cos(r/2), math.sin(r/2)
        cp, sp = math.cos(p/2), math.sin(p/2)
        cy, sy = math.cos(y/2), math.sin(y/2)
        return (sr*cp*cy-cr*sp*sy, cr*sp*cy+sr*cp*sy,
                cr*cp*sy-sr*sp*cy, cr*cp*cy+sr*sp*sy)

def main():
    rclpy.init()
    node = MoveToPose()
    # ▼ 여기에 목표 포즈 입력 ▼
    node.move(x=0.3, y=0.0, z=0.5, ry=180.0, speed=0.1)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

### Cartesian 직선 경로 (웨이포인트)

```python
#!/usr/bin/env python3
"""MoveIt2 Cartesian 직선 경로 — Plan + FollowJointTrajectory"""
import rclpy
from rclpy.node import Node
from moveit_msgs.srv import GetCartesianPath
from control_msgs.action import FollowJointTrajectory
from geometry_msgs.msg import Pose
from rclpy.action import ActionClient
import math

class CartesianPath(Node):
    def __init__(self):
        super().__init__('moveit2_cartesian')
        self._cart_client = self.create_client(GetCartesianPath, '/compute_cartesian_path')
        self._exec_client = ActionClient(self, FollowJointTrajectory,
            '/dsr_moveit_controller/follow_joint_trajectory')
        self._cart_client.wait_for_service(timeout_sec=10.0)
        self._exec_client.wait_for_server(timeout_sec=10.0)

    def execute_waypoints(self, waypoints, speed=0.1):
        req = GetCartesianPath.Request()
        req.header.frame_id = 'base_link'
        req.group_name = 'manipulator'
        req.max_step = 0.01
        req.jump_threshold = 0.0
        req.avoid_collisions = True

        for wp in waypoints:
            pose = Pose()
            pose.position.x, pose.position.y, pose.position.z = wp['x'], wp['y'], wp['z']
            qx, qy, qz, qw = self._rpy_to_quat(
                math.radians(wp.get('rx',0)), math.radians(wp.get('ry',0)), math.radians(wp.get('rz',0)))
            pose.orientation.x, pose.orientation.y = qx, qy
            pose.orientation.z, pose.orientation.w = qz, qw
            req.waypoints.append(pose)

        future = self._cart_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        resp = future.result()
        self.get_logger().info(f'경로 계산: {resp.fraction*100:.1f}% 달성')

        if resp.fraction < 0.9:
            self.get_logger().error('경로 90% 미만 — 실행 취소')
            return False

        goal = FollowJointTrajectory.Goal()
        goal.trajectory = resp.solution.joint_trajectory
        future = self._exec_client.send_goal_async(goal)
        rclpy.spin_until_future_complete(self, future)
        result_future = future.result().get_result_async()
        rclpy.spin_until_future_complete(self, result_future)

        if result_future.result().result.error_code == 0:
            self.get_logger().info('경로 실행 완료!')
            return True
        self.get_logger().error('실행 실패')
        return False

    def _rpy_to_quat(self, r, p, y):
        cr, sr = math.cos(r/2), math.sin(r/2)
        cp, sp = math.cos(p/2), math.sin(p/2)
        cy, sy = math.cos(y/2), math.sin(y/2)
        return (sr*cp*cy-cr*sp*sy, cr*sp*cy+sr*cp*sy,
                cr*cp*sy-sr*sp*cy, cr*cp*cy+sr*sp*sy)

def main():
    rclpy.init()
    node = CartesianPath()
    # ▼ 여기에 웨이포인트 입력 ▼
    waypoints = [
        {'x': 0.3, 'y': 0.0, 'z': 0.5, 'ry': 180},
        {'x': 0.3, 'y': 0.2, 'z': 0.5, 'ry': 180},
        {'x': 0.3, 'y': 0.2, 'z': 0.3, 'ry': 180},
    ]
    node.execute_waypoints(waypoints, speed=0.1)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

---

## 안전 체크리스트

Claude는 실행 전 아래를 확인한다:

1. **관절 범위**: 목표 관절 각도가 M1013 범위 내인지 확인
   - J3 ±160° 특히 주의 (다른 관절은 ±360°)
2. **속도 제한**: 협동로봇 안전 속도 0.25 m/s 이하 권장
   - speed > 0.3 시 사용자에게 경고
3. **Plan Only 우선**: 첫 실행 시 Plan Only로 경로 확인 후 Execute 권장
4. **충돌 검사**: Planning Scene에 장애물이 등록되어 있는지 확인
5. **특이점 회피**: 목표가 로봇 작업 영역 경계이면 경고

---

## 참고

- MoveIt2 상세 가이드: `knowledge-base/moveit2-guide.md`
- M1013 사양: `robots/doosan-m1013/README.md`
- Gazebo 가이드: `knowledge-base/gazebo-guide.md`
- 작업 프로그래밍: `/task-skill-library`
