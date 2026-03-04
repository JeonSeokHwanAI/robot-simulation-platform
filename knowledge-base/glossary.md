# 용어 사전 & 기술 가이드 인덱스

이 프로젝트에서 사용하는 핵심 기술과 용어를 정리한다.
상세 내용이 있는 항목은 개별 문서로 링크된다.

---

## 시뮬레이션 핵심 도구

| 용어 | 설명 | 상세 문서 |
|------|------|-----------|
| **Gazebo** | 물리 시뮬레이터. 중력, 충돌, 마찰, 센서를 시뮬레이션하는 가상 세계 | [gazebo-guide.md](gazebo-guide.md) |
| **MoveIt2** | 모션 플래닝 프레임워크. 충돌 회피 경로를 계산하고 로봇을 이동시키는 두뇌 역할 | [moveit2-guide.md](moveit2-guide.md) |
| **RViz** | ROS2 3D 시각화 도구. 로봇 모델, 센서 데이터, 경로 계획 결과를 시각화 | [moveit2-guide.md](moveit2-guide.md#rviz와의-관계) |

### Gazebo vs MoveIt2 사용 시점

| 목적 | 사용 도구 |
|------|-----------|
| 로봇 모델/URDF 시각적 확인 | Gazebo 단독 또는 RViz 단독 |
| 모션 플래닝 알고리즘 검증 | MoveIt2 단독 (FakeSystem) |
| 물건 잡기/놓기 시뮬레이션 | **Gazebo + MoveIt2 통합** |
| 실제 로봇 제어 | MoveIt2 + 실제 하드웨어 |

---

## ROS2 생태계

| 용어 | 설명 | 참고 |
|------|------|------|
| **ROS2 (Robot Operating System 2)** | 로봇 소프트웨어 개발 미들웨어. 노드 간 통신(토픽/서비스/액션), 빌드 시스템, 런치 시스템 제공 | [ros2-cheatsheet.md](ros2-cheatsheet.md) |
| **Humble Hawksbill** | 이 프로젝트에서 사용하는 ROS2 배포판 (Ubuntu 22.04 대응, LTS) | — |
| **노드 (Node)** | ROS2의 실행 단위. 하나의 프로세스가 하나 이상의 노드를 포함 | — |
| **토픽 (Topic)** | 노드 간 비동기 메시지 전달 채널 (발행-구독 패턴). 예: `/joint_states` | — |
| **서비스 (Service)** | 노드 간 동기식 요청-응답 통신. 예: `/compute_fk` (FK 계산) | — |
| **액션 (Action)** | 장시간 작업을 위한 비동기 통신 (목표 전송 → 피드백 → 결과). 예: `/move_action` | — |
| **Launch 파일** | 여러 노드를 한 번에 구성/실행하는 Python 스크립트 (.launch.py) | — |
| **colcon** | ROS2 빌드 도구. `colcon build`로 워크스페이스 내 패키지를 빌드 | — |
| **rosdep** | ROS2 의존성 관리 도구. 패키지의 시스템 의존성을 자동 설치 | — |

---

## 로봇 모델링

| 용어 | 설명 | 참고 |
|------|------|------|
| **URDF (Unified Robot Description Format)** | 로봇의 링크, 조인트, 물성, 시각 메쉬를 XML로 기술하는 표준 포맷 | — |
| **Xacro** | URDF의 매크로 확장. 파라미터, 조건부 포함 등으로 URDF 재사용성 향상 | — |
| **SRDF (Semantic Robot Description Format)** | MoveIt2용 의미 정보 기술 파일. 플래닝 그룹, 기본 자세, 자체 충돌 비활성 쌍 정의 | — |
| **링크 (Link)** | 로봇의 강체 부품 (base_link, link_1~link_6). 시각 메쉬와 충돌 메쉬를 가짐 | — |
| **조인트 (Joint)** | 링크 간 연결부. 회전(revolute), 고정(fixed), 직선(prismatic) 등 유형이 있음 | — |
| **자유도 (DOF, Degrees of Freedom)** | 로봇이 독립적으로 움직일 수 있는 축의 수. M1013과 R12 모두 6축 | — |

---

## 로봇 제어

| 용어 | 설명 | 참고 |
|------|------|------|
| **ros2_control** | ROS2의 하드웨어 추상화 프레임워크. 실제 로봇이든 시뮬레이터든 동일한 인터페이스로 제어 | — |
| **컨트롤러 (Controller)** | 조인트 명령을 생성하는 모듈. `joint_state_broadcaster`, `dsr_controller2`, `dsr_moveit_controller` 등 | — |
| **joint_state_broadcaster** | 현재 조인트 상태(위치/속도)를 `/joint_states` 토픽으로 발행하는 컨트롤러 | — |
| **FollowJointTrajectory** | MoveIt2가 계획한 경로를 실행하는 액션 인터페이스 | — |
| **FakeSystem** | ros2_control의 가상 하드웨어. 물리 시뮬레이터 없이 명령값을 즉시 상태로 반영 | — |

---

## 운동학 (Kinematics)

| 용어 | 설명 | 참고 |
|------|------|------|
| **FK (Forward Kinematics)** | 조인트 각도 → 엔드이펙터 위치/방향을 계산. "각 조인트가 이 각도이면 팔끝은 어디에?" | — |
| **IK (Inverse Kinematics)** | 엔드이펙터 위치/방향 → 필요한 조인트 각도를 계산. "팔끝을 여기 두려면 각 조인트는?" | — |
| **엔드이펙터 (End Effector)** | 로봇 팔 끝에 부착된 작업 도구 (그리퍼, 용접기 등). M1013의 경우 link_6 끝 | — |
| **TCP (Tool Center Point)** | 엔드이펙터의 작업 기준점. 좌표계 원점 | — |
| **포즈 (Pose)** | 위치(x,y,z) + 방향(쿼터니언 또는 오일러)의 조합. 6자유도 정보 | — |
| **쿼터니언 (Quaternion)** | 3D 회전을 4개의 값(qx,qy,qz,qw)으로 표현. 짐벌 락 문제가 없어 로봇에서 표준 사용 | — |

---

## 모션 플래닝 알고리즘

| 용어 | 설명 | 참고 |
|------|------|------|
| **OMPL** | 샘플링 기반 모션 플래너. RRT*, PRM 등 다양한 알고리즘 포함. MoveIt2 기본 플래너 | [moveit2-guide.md](moveit2-guide.md#플래너-비교) |
| **CHOMP** | 최적화 기반 플래너. 초기 경로를 반복 최적화하여 장애물 회피 경로 생성 | [moveit2-guide.md](moveit2-guide.md#플래너-비교) |
| **Pilz Industrial Motion Planner** | 산업용 플래너. PTP(점 대 점), LIN(직선), CIRC(원호) 세 가지 정밀 모션 제공 | [moveit2-guide.md](moveit2-guide.md#플래너-비교) |

---

## Doosan 전용 용어

| 용어 | 설명 | 참고 |
|------|------|------|
| **DRCF (Doosan Robot Controller Framework)** | 두산 로봇 컨트롤러 소프트웨어. 에뮬레이터 모드로 PC에서 가상 실행 가능 | — |
| **doosan-robot2** | 두산 로보틱스 공식 ROS2 패키지 (22개 패키지). M1013 등 전 기종 지원 | — |
| **dsr_controller2** | 두산 로봇 전용 ros2_control 컨트롤러. DRCF와 직접 통신 | — |
| **dsr_moveit_controller** | MoveIt2의 trajectory를 두산 로봇에 전달하는 FollowJointTrajectory 컨트롤러 | — |

---

## 인프라 & 환경

| 용어 | 설명 | 참고 |
|------|------|------|
| **WSL2 (Windows Subsystem for Linux 2)** | Windows에서 Linux를 네이티브 실행하는 가상화 레이어. Ubuntu 22.04 구동에 사용 | [installation-guide.md](installation-guide.md) |
| **WSLg** | WSL2의 GUI 앱 지원 기능. X11/Wayland 앱을 Windows에서 표시 | — |
| **Docker** | 컨테이너 가상화 플랫폼. DRCF 에뮬레이터 실행에 사용 | — |

---

## 문서 목록

### knowledge-base (공통 기술)

| 파일명 | 내용 |
|--------|------|
| [gazebo-guide.md](gazebo-guide.md) | Gazebo 시뮬레이터 상세 가이드 |
| [moveit2-guide.md](moveit2-guide.md) | MoveIt2 모션 플래닝 상세 가이드 |
| [ros2-cheatsheet.md](ros2-cheatsheet.md) | ROS2 주요 명령어 모음 |
| [installation-guide.md](installation-guide.md) | 환경 구축 가이드 (13단계) |
| [lessons-learned.md](lessons-learned.md) | 트러블슈팅 & 노하우 |
| [external-resources.md](external-resources.md) | 외부 참고 링크 |

### robots (기종별 사양)

| 파일명 | 내용 |
|--------|------|
| [Doosan M1013](../robots/doosan-m1013/README.md) | 사양, 통신, ROS2 연동, DRCF 에뮬레이터 |
| [CGXI R12](../robots/cgxi-r12/README.md) | 사양, 조인트, DH 파라미터, 통신, I/O, 벤더 자료 |
