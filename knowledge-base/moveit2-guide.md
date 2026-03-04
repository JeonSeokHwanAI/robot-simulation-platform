# MoveIt2 모션 플래닝 가이드

> 용어 인덱스로 돌아가기: [glossary.md](glossary.md)
> Gazebo와의 관계: [gazebo-guide.md](gazebo-guide.md)

---

## 개요

MoveIt2는 ROS2 기반 **모션 플래닝 프레임워크**이다.
로봇 팔이 현재 위치에서 목표 위치까지 **충돌 없이** 이동하는 경로를 자동으로 계산한다.

### 핵심 역할
- **모션 플래닝**: 시작 자세 → 목표 자세 경로 생성 (장애물 회피)
- **역운동학 (IK)**: 원하는 엔드이펙터 포즈에 필요한 조인트 각도 계산
- **충돌 검사**: 로봇 자체 간, 로봇과 환경 간 충돌 감지
- **경로 실행**: 계획된 경로를 컨트롤러에 전달하여 실행

### 비유
MoveIt2는 로봇의 **두뇌**이다.
"이 물건을 집어라"라는 명령을 받으면, 어떤 경로로 팔을 움직여야
다른 것에 부딪히지 않고 도달할 수 있는지를 계산한다.

---

## 아키텍처

```
사용자 / 프로그램
       │
       ▼
┌─────────────────────────────────────┐
│           move_group 노드            │
│  ┌───────────┐  ┌────────────────┐  │
│  │ Planning  │  │  Planning      │  │
│  │ Pipeline  │  │  Scene         │  │
│  │ (OMPL 등) │  │  (충돌 환경)    │  │
│  └───────────┘  └────────────────┘  │
│  ┌───────────┐  ┌────────────────┐  │
│  │ Kinematics│  │  Trajectory    │  │
│  │ (FK/IK)   │  │  Execution     │  │
│  └───────────┘  └────────────────┘  │
└──────────────┬──────────────────────┘
               │ FollowJointTrajectory
               ▼
┌─────────────────────────────────────┐
│         ros2_control                │
│  (controller_manager)              │
│  ├── joint_state_broadcaster       │
│  ├── dsr_controller2               │
│  └── dsr_moveit_controller         │
└──────────────┬──────────────────────┘
               │
               ▼
     실제 로봇 / Gazebo / FakeSystem
```

### 핵심 구성 요소

| 구성 요소 | 역할 |
|-----------|------|
| **move_group** | MoveIt2의 중앙 노드. 플래닝, 실행, 씬 관리를 통합 제공 |
| **Planning Pipeline** | 모션 플래닝 알고리즘 실행 파이프라인 |
| **Planning Scene** | 로봇과 환경의 충돌 모델을 관리하는 가상 씬 |
| **Kinematics Solver** | FK/IK 계산 (기본: KDL) |
| **Trajectory Execution** | 계획된 경로를 컨트롤러에 전달하여 실행 |

---

## 플래너 비교

이 프로젝트에서 사용 가능한 3종 플래너:

### OMPL (기본 플래너)
- **방식**: 샘플링 기반 (Configuration Space에서 랜덤 샘플링)
- **알고리즘**: RRT, RRT*, PRM, BiEST, KPIECE 등 다수
- **장점**: 범용적, 고차원 공간에서 효율적, 다양한 알고리즘 선택 가능
- **단점**: 경로가 비최적적일 수 있음 (후처리로 개선)
- **용도**: 일반적인 모션 플래닝, 장애물이 복잡한 환경

### CHOMP
- **방식**: 최적화 기반 (초기 경로를 비용 함수로 반복 최적화)
- **장점**: 매끄러운 경로 생성, 장애물 근접 회피
- **단점**: 초기 경로 품질에 의존, 지역 최적해에 빠질 수 있음
- **용도**: 장애물 회피가 중요한 작업, 경로 품질 최적화

### Pilz Industrial Motion Planner
- **방식**: 결정론적 (수학적으로 정확한 경로 계산)
- **모션 유형**:
  - **PTP** (Point-to-Point): 조인트 공간에서 최단 이동
  - **LIN** (Linear): 작업 공간에서 직선 이동
  - **CIRC** (Circular): 작업 공간에서 원호 이동
- **장점**: 예측 가능, 반복 실행 시 동일 경로, 산업 표준 모션
- **단점**: 장애물 회피 기능 없음
- **용도**: Pick & Place (LIN으로 정밀 접근), 용접/도포 (CIRC로 원호 경로)

### 플래너 선택 가이드

| 상황 | 추천 플래너 |
|------|------------|
| 복잡한 환경에서 자유로운 이동 | OMPL (RRTConnect) |
| 장애물 근처 매끄러운 경로 | CHOMP |
| 직선으로 물건 접근/후퇴 | Pilz LIN |
| 점 대 점 빠른 이동 | Pilz PTP |
| 원형 경로 (용접, 도포) | Pilz CIRC |

---

## RViz와의 관계

RViz는 **시각화 도구**이다. MoveIt2와 결합하면:

- 로봇의 현재 자세를 3D로 표시
- **인터랙티브 마커**: 마우스로 엔드이펙터의 목표 포즈를 직관적으로 설정
- **경로 시각화**: 계획된 경로를 애니메이션으로 미리 확인
- **Planning Scene 편집**: 장애물(박스, 실린더 등)을 GUI로 추가/제거
- **Plan / Execute / Plan & Execute** 버튼으로 GUI 제어

### RViz MotionPlanning 패널 사용법
1. **Context 탭**: 플래너 선택 (OMPL/CHOMP/Pilz)
2. **Planning 탭**: Plan / Execute 버튼, 속도 스케일링 조절
3. **Joints 탭**: 개별 조인트 각도를 슬라이더로 직접 조절
4. **Scene Objects 탭**: 충돌 객체(박스, 실린더 등) 추가
5. 인터랙티브 마커(주황색 로봇): 드래그하여 목표 포즈 설정

---

## 프로그래밍 인터페이스

### 1. MoveGroup Action (Python)
`/move_action` 액션을 통해 프로그래밍 방식으로 모션 플래닝 및 실행:

```python
from rclpy.action import ActionClient
from moveit_msgs.action import MoveGroup
from moveit_msgs.msg import MotionPlanRequest, Constraints, JointConstraint

# 액션 클라이언트 생성
move_action = ActionClient(node, MoveGroup, '/move_action')

# 목표 설정
goal = MoveGroup.Goal()
goal.request.group_name = 'manipulator'
goal.request.pipeline_id = 'ompl'
goal.request.num_planning_attempts = 10
goal.request.allowed_planning_time = 5.0

# plan_only=True → 계획만, False → 계획 + 실행
goal.planning_options.plan_only = False
```

### 2. MoveIt2 서비스
| 서비스 | 용도 |
|--------|------|
| `/compute_fk` | FK 계산 (조인트 각도 → 엔드이펙터 포즈) |
| `/compute_ik` | IK 계산 (엔드이펙터 포즈 → 조인트 각도) |
| `/plan_kinematic_path` | 모션 플래닝 (경로 계산만) |
| `/get_planning_scene` | 현재 Planning Scene 정보 조회 |

### 3. MoveGroupInterface (C++ / Python)
더 높은 수준의 API로 간결하게 사용 가능:

```python
from moveit_msgs.msg import MoveItErrorCodes
# RViz에서 사용하는 것과 동일한 인터페이스
# move_group_interface로 goal pose 설정 → plan() → execute()
```

---

## 이 프로젝트에서의 MoveIt2 구성

### 실행 명령
```bash
# MoveIt2 단독 (Gazebo 없이, FakeSystem 사용)
ros2 launch dsr_bringup2 dsr_bringup2_moveit.launch.py mode:=virtual host:=127.0.0.1 port:=12345 model:=m1013
```

### 실행되는 프로세스 구조
```
dsr_bringup2_moveit.launch.py
├── run_emulator (DRCF 에뮬레이터 시작)
├── robot_state_publisher (URDF → TF)
├── controller_manager (ros2_control)
│   ├── joint_state_broadcaster (5초 후 시작)
│   ├── dsr_controller2 (JSB 완료 후 시작)
│   └── dsr_moveit_controller (dsr_controller2 완료 후 시작)
├── move_group (MoveIt2 중앙 노드)
│   ├── OMPL 플래닝 파이프라인
│   ├── CHOMP 플래닝 파이프라인
│   └── Pilz 플래닝 파이프라인
└── rviz2 (인터랙티브 마커 + 시각화)
```

### M1013 MoveIt2 설정 파일
| 파일 | 역할 |
|------|------|
| `m1013.urdf.xacro` | 로봇 모델 정의 |
| `dsr.srdf` | Planning Group, 기본 자세, 자체 충돌 비활성 쌍 |
| `kinematics.yaml` | IK 솔버 설정 (KDL) |
| `ompl_planning.yaml` | OMPL 알고리즘 파라미터 |
| `chomp_planning.yaml` | CHOMP 알고리즘 파라미터 |
| `pilz_industrial_motion_planner_planning.yaml` | Pilz 설정 |
| `moveit_controllers.yaml` | MoveIt2 ↔ 컨트롤러 매핑 |
| `ros2_controllers.yaml` | ros2_control 컨트롤러 정의 |
| `joint_limits.yaml` | 조인트 속도/가속도 제한 |
| `moveit.rviz` | RViz 레이아웃 설정 |

모든 파일 위치: `~/ros2_ws/src/doosan-robot2/dsr_moveit2/dsr_moveit_config_m1013/`

---

## 검증된 테스트 결과 (2026-03-04)

| 테스트 | 결과 | 소요 시간 |
|--------|------|-----------|
| FK 계산 (Home → 엔드이펙터 포즈) | 성공: x=0.0, y=0.03, z=1.45m | 즉시 |
| Plan Only (OMPL, 6축 동시 이동) | 성공: 45개 경로 포인트 생성 | 0.04s |
| Plan & Execute (목표 포즈 이동) | 성공: 오차 < 1° | 4.55s |
| Home 복귀 | 성공: 오차 < 0.5° | 4.89s |

---

## Gazebo + MoveIt2 통합 (Pick & Place용)

MoveIt2 단독 모드에서는 물리 시뮬레이션이 없다.
물건을 집는 등의 물리 상호작용이 필요하면 Gazebo와 통합해야 한다.

```
통합 구조:
  Gazebo (물리 세계)
    ↕ ign_ros2_control
  ros2_control (하드웨어 추상화)
    ↕ FollowJointTrajectory
  MoveIt2 move_group (경로 계획)
    ↕ 인터랙티브 마커 / Python API
  사용자
```

통합 시 ros2_control이 Gazebo의 시뮬레이션 조인트를 직접 제어하므로,
MoveIt2가 계획한 경로대로 Gazebo 안의 로봇이 실제로 움직인다.

---

## 프로젝트 내 관련 파일

| 파일 | 위치 |
|------|------|
| MoveIt2 launch | `~/ros2_ws/src/doosan-robot2/dsr_bringup2/launch/dsr_bringup2_moveit.launch.py` |
| M1013 MoveIt config | `~/ros2_ws/src/doosan-robot2/dsr_moveit2/dsr_moveit_config_m1013/` |
| MoveIt 연동 노드 | `~/ros2_ws/src/doosan-robot2/dsr_bringup2/dsr_bringup2/moveit_connection.py` |
| M1013 demo launch | `~/ros2_ws/src/doosan-robot2/dsr_moveit2/dsr_moveit_config_m1013/launch/demo.launch.py` |
| 테스트 스크립트 | `/tmp/moveit_test.py` (WSL2 내) |
| 외부 참고 | [MoveIt2 공식 문서](https://moveit.picknik.ai/humble/index.html) |
