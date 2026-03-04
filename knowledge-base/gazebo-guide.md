# Gazebo 시뮬레이터 가이드

> 용어 인덱스로 돌아가기: [glossary.md](glossary.md)
> MoveIt2와의 관계: [moveit2-guide.md](moveit2-guide.md)

---

## 개요

Gazebo는 로봇을 위한 **물리 시뮬레이터**이다.
현실 세계를 가상으로 재현하여 로봇이 실제 환경에서 어떻게 동작하는지를 시뮬레이션한다.

### 핵심 역할
- **물리 엔진**: 중력, 충돌, 마찰, 관성을 계산
- **3D 렌더링**: 로봇과 환경을 시각적으로 표시
- **센서 시뮬레이션**: 카메라, LiDAR, IMU 등 가상 센서 데이터 생성
- **환경 구성**: 테이블, 물체, 벽 등 월드(World)를 구성

### 비유
Gazebo는 **로봇이 놓이는 공장 바닥**이다.
중력이 있고, 물건이 있고, 부딪히면 밀린다.
하지만 Gazebo 자체는 "어디로 이동해라"를 판단하지 않는다.

---

## Gazebo Classic vs Ignition Gazebo (Fortress)

이 프로젝트에서는 **Ignition Gazebo (Fortress)**를 사용한다.

| 항목 | Gazebo Classic (11.x) | Ignition Gazebo (Fortress) |
|------|----------------------|---------------------------|
| 아키텍처 | 모놀리식 | 모듈러 (라이브러리 기반) |
| 렌더링 | OGRE 1.x | OGRE 1.x / OGRE 2.x 선택 |
| 물리 엔진 | ODE, Bullet, DART, Simbody | DART (기본), Bullet, TPE |
| ROS2 연동 | gazebo_ros_pkgs | ros_gz (ros-humble-ros-gz) |
| ros2_control | gazebo_ros2_control | ign_ros2_control |
| 유지보수 | 종료 예정 | 활발한 개발 |

### 왜 Ignition Gazebo인가?
- doosan-robot2 공식 패키지가 Ignition Gazebo를 대상으로 개발됨
- Gazebo Classic은 ROS2 Humble 이후 공식 지원 종료 예정
- 모듈러 구조로 확장성이 더 좋음

---

## 이 프로젝트에서의 Gazebo 구성

### 설치된 패키지
```
ros-humble-ros-gz         : Ignition Gazebo ↔ ROS2 브릿지
ros-humble-ign-ros2-control : Ignition Gazebo에서 ros2_control 사용
```

### 실행 명령
```bash
ros2 launch dsr_bringup2 dsr_bringup2_gazebo.launch.py mode:=virtual host:=127.0.0.1 port:=12345 model:=m1013
```

### 실행되는 프로세스 구조
```
dsr_bringup2_gazebo.launch.py
├── DRCF 에뮬레이터 (Docker 컨테이너)
├── Ignition Gazebo (물리 시뮬레이션 + 3D 렌더링)
│   └── ign_ros2_control 플러그인 (ros2_control 연동)
├── robot_state_publisher (URDF → TF 변환 발행)
├── controller_manager (ros2_control 관리)
│   ├── joint_state_broadcaster
│   └── dsr_controller2
└── ros_gz_bridge (Gazebo ↔ ROS2 토픽 브릿지)
```

### WSL2 렌더링 설정
WSL2에서는 GPU 호환성 문제로 다음 환경변수가 필요하다:
```bash
export IGN_GAZEBO_RENDER_ENGINE_GUI=ogre      # Ogre2 → Ogre1
export IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre
export LIBGL_ALWAYS_SOFTWARE=1                 # 소프트웨어 렌더링
```
- 성능: 약 82% 실시간 속도 (기능 검증에는 충분)
- 자세한 내용: [lessons-learned.md](lessons-learned.md)

---

## Gazebo 주요 개념

### World (월드)
시뮬레이션 환경의 전체 정의 파일 (.sdf 또는 .world).
지면, 조명, 물체, 로봇 배치 등을 포함한다.

### Model (모델)
월드 안에 배치되는 개별 객체.
로봇, 테이블, 박스 등 각각이 하나의 모델이다.
URDF 또는 SDF 형식으로 정의된다.

### Plugin (플러그인)
Gazebo의 기능을 확장하는 모듈.
센서 데이터 발행, ros2_control 연동 등에 사용된다.
- `ign_ros2_control`: ros2_control 하드웨어 인터페이스
- `ros_gz_bridge`: Gazebo 토픽 ↔ ROS2 토픽 변환

### SDF (Simulation Description Format)
Gazebo 네이티브 모델/월드 기술 형식.
URDF보다 풍부한 물리 속성(마찰계수, 접촉강성 등)을 기술할 수 있다.

---

## Gazebo를 사용하는 경우 vs 사용하지 않는 경우

### Gazebo가 필요한 경우
- 물리 상호작용 시뮬레이션 (물건 집기, 충돌 등)
- 센서 데이터 시뮬레이션 (카메라, LiDAR)
- 환경 내 로봇 동작 검증 (장애물 회피 등)
- 복수 로봇 협업 시뮬레이션

### Gazebo가 불필요한 경우
- 모션 플래닝 알고리즘 테스트만 할 때 → MoveIt2 단독 (FakeSystem)
- URDF 시각적 확인만 할 때 → RViz 단독
- 실제 로봇을 직접 제어할 때 → MoveIt2 + 실제 하드웨어

---

## 프로젝트 내 관련 파일

| 파일 | 위치 |
|------|------|
| Gazebo launch | `~/ros2_ws/src/doosan-robot2/dsr_bringup2/launch/dsr_bringup2_gazebo.launch.py` |
| Gazebo 연동 노드 | `~/ros2_ws/src/doosan-robot2/dsr_bringup2/dsr_bringup2/gazebo_connection.py` |
| M1013 URDF/Xacro | `~/ros2_ws/src/doosan-robot2/dsr_description2/xacro/m1013.urdf.xacro` |
| Gazebo 패키지 | `~/ros2_ws/src/doosan-robot2/dsr_gazebo2/` |
| 환경 구축 가이드 | [installation-guide.md](installation-guide.md) Step 9~11 |
| 트러블슈팅 | [lessons-learned.md](lessons-learned.md) |
