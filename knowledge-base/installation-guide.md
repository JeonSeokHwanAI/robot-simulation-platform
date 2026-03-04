# 시뮬레이션 환경 구축 가이드

> 용어 인덱스: [glossary.md](glossary.md) | Gazebo: [gazebo-guide.md](gazebo-guide.md) | MoveIt2: [moveit2-guide.md](moveit2-guide.md)

> Doosan M1013 협업로봇의 디지털 트윈 시뮬레이션을 위한 전체 환경 구축 가이드.
> Windows 10 위에서 WSL2 → Ubuntu → ROS2 → Gazebo → MoveIt2 → Docker → Doosan 패키지까지
> 각 구성요소가 **무엇이고, 왜 필요한지** 설명한다.

---

## 전체 아키텍처

```
Windows 10 (Host OS)
│
└── WSL2 (Windows Subsystem for Linux 2)
    │
    └── Ubuntu 22.04 (Jammy Jellyfish)
        │
        ├── ROS2 Humble ─────────── 로봇 소프트웨어 프레임워크
        │   ├── Gazebo 11 ────────── 3D 물리 시뮬레이터
        │   ├── MoveIt2 ──────────── 모션 플래닝 프레임워크
        │   ├── ros2_control ──────── 로봇 하드웨어 추상화 계층
        │   └── 기타 도구 ─────────── xacro, joint_state_publisher 등
        │
        ├── Docker ────────────────── DRCF 에뮬레이터 실행 환경
        │
        ├── colcon ────────────────── ROS2 빌드 시스템
        ├── rosdep ────────────────── ROS2 의존성 관리 도구
        │
        └── doosan-robot2 (22 패키지) ── 두산 로봇 ROS2 공식 패키지
            ├── dsr_bringup2 ────────── 시뮬레이션/실기 런치 파일
            ├── dsr_description2 ────── URDF 로봇 모델
            ├── dsr_gazebo2 ─────────── Gazebo 시뮬레이션 통합
            ├── dsr_controller2 ─────── 로봇 제어기
            ├── dsr_hardware2 ───────── 하드웨어 인터페이스
            ├── dsr_moveit_config_m1013 ── M1013 MoveIt 설정
            └── ... (기타 패키지)
```

---

## Step 1: WSL2 + Ubuntu 22.04

### 이것은 무엇인가?
- **WSL2** (Windows Subsystem for Linux 2): Windows 안에서 리눅스를 실행하는 가상화 기술
- **Ubuntu 22.04**: ROS2 Humble이 공식 지원하는 리눅스 배포판

### 왜 필요한가?
- ROS2는 **리눅스(Ubuntu) 전용** 소프트웨어이다
- Windows에서 직접 실행할 수 없으므로 WSL2를 통해 리눅스 환경을 만든다
- WSL2는 실제 리눅스 커널을 사용하므로 VirtualBox보다 성능이 좋다

### 설치

```powershell
# PowerShell (관리자 권한)
wsl --install -d Ubuntu-22.04
```

### 설치 확인

```bash
lsb_release -a
# Ubuntu 22.04.x LTS 가 출력되면 정상

uname -r
# 6.x.x-microsoft-standard-WSL2 형태가 출력되면 WSL2 정상
```

### 설치 결과 (2026-03-03)
- Ubuntu 22.04.5 LTS
- Kernel: 6.6.87.2-microsoft-standard-WSL2
- User: shjeon@SHJEON

---

## Step 2: ROS2 Humble Hawksbill

### 이것은 무엇인가?
**ROS2** (Robot Operating System 2)는 로봇 소프트웨어 개발을 위한 오픈소스 프레임워크이다.
운영체제가 아니라, 로봇 개발에 필요한 도구/라이브러리/통신 규격의 모음이다.

**Humble Hawksbill**은 ROS2의 LTS(장기지원) 버전으로, Ubuntu 22.04에 대응한다.

### 왜 필요한가?
| 기능 | 설명 |
|------|------|
| 노드 통신 | 로봇의 센서, 제어기, 플래너 등이 서로 데이터를 주고받는 표준 통신 구조 (Topic, Service, Action) |
| 런치 시스템 | 여러 프로그램을 한 번에 실행/관리하는 시스템 (`ros2 launch`) |
| 패키지 관리 | 로봇 관련 소프트웨어를 패키지 단위로 관리 |
| 시뮬레이션 연동 | Gazebo, MoveIt2 등 시뮬레이션 도구와 표준화된 인터페이스 |
| 실기 연동 | 시뮬레이션에서 개발한 코드를 실제 로봇에 그대로 적용 가능 |

### 설치

> **주의**: WSL2 터미널에 명령어 붙여넣기 시 `\` 줄바꿈이 Enter로 실행될 수 있다.
> 모든 명령어를 한 줄씩 복사-붙여넣기 할 것.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common
sudo add-apt-repository universe
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt install -y ros-humble-desktop
echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

### 설치 확인

```bash
# ros2 명령어가 응답하면 정상 (ros2 --version 은 존재하지 않음)
ros2 topic list

# 상세 확인
ros2 doctor --report
```

### 설치 결과 (2026-03-03)
- ROS2 Humble 정상 설치
- `ros2 doctor --report`에서 네트워크 설정 확인 (lo: 127.0.0.1, eth0: 172.27.115.104)

---

## Step 3: Gazebo (3D 물리 시뮬레이터)

### 이것은 무엇인가?
**Gazebo**는 로봇의 3D 물리 시뮬레이션 환경이다.
실제 로봇 없이도 로봇의 움직임, 센서, 충돌, 중력 등을 시뮬레이션할 수 있다.

### 왜 필요한가?
| 용도 | 설명 |
|------|------|
| 디지털 트윈 | 실제 로봇과 동일한 가상 로봇을 3D 환경에서 구동 |
| 안전한 테스트 | 실제 로봇으로 테스트하기 전에 궤적/충돌을 검증 |
| 물리 시뮬레이션 | 중력, 마찰, 관성 등 물리 법칙이 적용된 시뮬레이션 |
| 센서 시뮬레이션 | 카메라, LiDAR 등 센서 데이터도 가상으로 생성 가능 |

### 설치

```bash
sudo apt install -y ros-humble-gazebo-ros-pkgs
```

### 설치 확인

```bash
gazebo --version
# Gazebo multi-robot simulator, version 11.x.x 가 출력되면 정상
```

### 설치 결과 (2026-03-03)
- Gazebo 11.10.2

---

## Step 4: MoveIt2 (모션 플래닝)

### 이것은 무엇인가?
**MoveIt2**는 로봇 팔의 모션 플래닝(경로 계획) 프레임워크이다.
"A 지점에서 B 지점으로 로봇 팔을 움직여라"라고 지시하면,
충돌 없이 갈 수 있는 궤적을 자동으로 계산해준다.

### 왜 필요한가?
| 기능 | 설명 |
|------|------|
| 경로 계획 | 시작점 → 목표점 사이의 최적 궤적 자동 계산 |
| 충돌 회피 | 로봇 자체 간섭 및 장애물 충돌을 자동 감지/회피 |
| 역기구학 | 목표 좌표(x,y,z) → 각 관절 각도 자동 계산 |
| Pick & Place | 물체 잡기/놓기 등의 작업을 프로그래밍 |
| RViz 연동 | 시각적으로 궤적을 확인하고 인터랙티브하게 조작 가능 |

### 설치

```bash
sudo apt install -y ros-humble-moveit
```

### 설치 확인

```bash
ros2 pkg list | grep moveit
# moveit_core, moveit_planners, moveit_ros 등 30+ 패키지가 출력되면 정상
```

### 설치 결과 (2026-03-03)
- MoveIt2 관련 30+ 패키지 설치 완료

---

## Step 5: ros2_control + 보조 도구

### 이것은 무엇인가?

| 패키지 | 역할 |
|--------|------|
| **ros2_control** | 로봇 하드웨어(모터, 센서)를 추상화하는 프레임워크. 시뮬레이션과 실기를 동일한 인터페이스로 제어 가능 |
| **ros2_controllers** | position_controller, joint_trajectory_controller 등 표준 제어기 모음 |
| **xacro** | URDF 파일을 매크로/변수로 간결하게 작성하는 XML 확장 도구 |
| **joint_state_publisher_gui** | RViz에서 슬라이더로 로봇 관절을 수동 조작하는 도구 |

### 왜 필요한가?
- ros2_control: Gazebo 시뮬레이션과 실제 로봇 하드웨어를 동일한 코드로 제어
- xacro: 두산 URDF 파일이 xacro 형식으로 작성되어 있음
- joint_state_publisher_gui: URDF 로딩 테스트 및 관절 동작 시각적 확인

### 설치

```bash
sudo apt install -y ros-humble-joint-state-publisher-gui ros-humble-xacro ros-humble-ros2-control ros-humble-ros2-controllers
```

### 설치 확인

```bash
ros2 pkg list | grep controller
# controller_manager, joint_trajectory_controller 등 20+ 패키지가 출력되면 정상
```

### 설치 결과 (2026-03-03)
- ros2_controllers 관련 20+ 패키지 설치 완료

---

## Step 6: Docker

### 이것은 무엇인가?
**Docker**는 애플리케이션을 격리된 컨테이너에서 실행하는 가상화 플랫폼이다.

### 왜 필요한가?
두산 로봇의 **DRCF(Doosan Robot Controller Framework) 에뮬레이터**를 Docker 컨테이너로 실행하기 위해 필요하다.

| 개념 | 설명 |
|------|------|
| DRCF | 두산 로봇의 실제 제어 소프트웨어. 물리적 제어 캐비닛(K20)에서 실행됨 |
| DRCF 에뮬레이터 | DRCF를 PC에서 가상으로 실행하는 프로그램 (Docker 컨테이너) |
| 용도 | 실제 로봇 없이도 ROS2 ↔ 로봇 제어기 간 통신을 테스트할 수 있음 |

```
[ROS2 노드] ←→ [DRCF 에뮬레이터 (Docker)] ←→ [Gazebo 시뮬레이션]
                     │
                     └── 실기 전환 시: [실제 K20 제어 캐비닛] 으로 교체
```

### 설치

```bash
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```

> `usermod` 후 WSL 재시작 필요: PowerShell에서 `wsl --shutdown` → WSL 다시 열기

### 설치 확인

```bash
sudo docker --version
# Docker version 28.x.x 가 출력되면 정상
```

### 설치 결과 (2026-03-03)
- Docker 28.2.2

---

## Step 7: ROS2 빌드 도구 (rosdep + colcon)

### 이것은 무엇인가?

| 도구 | 역할 |
|------|------|
| **colcon** | ROS2 패키지를 빌드(컴파일)하는 도구. `catkin_make`의 ROS2 버전 |
| **rosdep** | ROS2 패키지의 시스템 의존성을 자동으로 설치하는 도구 |

### 왜 필요한가?
- 두산 doosan-robot2 패키지는 **소스코드** 형태로 배포됨
- 소스코드를 실행 가능한 형태로 빌드(컴파일)해야 함
- 빌드 전에 필요한 라이브러리를 자동으로 찾아 설치해야 함

```
[GitHub 소스] → rosdep (의존성 설치) → colcon build (컴파일) → [실행 가능 패키지]
```

### 설치

```bash
sudo apt install -y python3-rosdep2 python3-colcon-common-extensions
sudo rosdep init
rosdep update
```

> `sudo rosdep init`에서 "already initialized" 메시지가 나오면 무시

> **참고**: ros-humble-desktop에 rosdep/colcon이 포함되지 않으므로 별도 설치 필요

---

## Step 8: Doosan doosan-robot2 패키지

### 이것은 무엇인가?
두산 로보틱스가 공식 제공하는 **ROS2 패키지 모음**이다.
M1013을 포함한 두산 협업로봇을 ROS2에서 제어하기 위한 모든 것이 들어있다.

### 패키지 구성 (22개)

| 패키지 | 역할 |
|--------|------|
| `dsr_bringup2` | 시뮬레이션/실기 런치 파일. **모든 실행의 시작점** |
| `dsr_description2` | URDF 로봇 모델 (3D 형상, 관절 정의, 충돌 모델) |
| `dsr_gazebo2` | Gazebo 시뮬레이션 월드 및 플러그인 |
| `dsr_controller2` | 로봇 관절 제어기 (ROS2 → 로봇 명령 변환) |
| `dsr_hardware2` | 하드웨어 인터페이스 (실기/에뮬레이터 통신 계층) |
| `dsr_moveit_config_m1013` | M1013 전용 MoveIt2 설정 (경로 계획 설정) |
| `dsr_common2` | 공용 유틸리티 |
| `dsr_msgs2` | 커스텀 ROS2 메시지/서비스 정의 |
| `dsr_example` | 예제 코드 |
| `dsr_tests` | 테스트 코드 |
| `dsr_mujoco` | MuJoCo 시뮬레이터 연동 |
| `dsr_realtime_control` | 실시간 제어 |
| `dsr_visualservoing` | 비전 기반 서보잉 |
| `dsr_moveit_config_*` | 각 로봇 모델별 MoveIt 설정 (a0509, a0912, m0609 등) |

### 설치

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src && git clone https://github.com/doosan-robotics/doosan-robot2.git
cd ~/ros2_ws && rosdep install --from-paths src --ignore-src -r -y
cd ~/ros2_ws && colcon build
echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc && source ~/.bashrc
```

### 설치 확인

```bash
ros2 pkg list | grep dsr
# dsr_bringup2, dsr_description2, dsr_moveit_config_m1013 등 22개 패키지 출력되면 정상
```

### 설치 결과 (2026-03-03)
- 22개 패키지 빌드 완료 (3분 9초)
- 경고: dsr_controller2, dsr_hardware2에서 deprecated API 경고 (기능 무관)

---

## Step 9: DRCF 에뮬레이터 (Docker 이미지)

### 이것은 무엇인가?
**DRCF**(Doosan Robot Controller Framework)는 두산 로봇의 실제 제어 소프트웨어이다.
물리적으로는 K20 제어 캐비닛에서 실행되지만, **Docker 컨테이너로 가상 실행**할 수 있다.

### 왜 필요한가?
- 실제 로봇 없이도 ROS2 ↔ 로봇 제어기 간 통신을 테스트
- `dsr_bringup2_gazebo.launch.py`에서 `mode:=virtual` 사용 시 자동으로 DRCF 컨테이너를 시작/정리

```
[ROS2 노드] ←→ [DRCF 에뮬레이터 (Docker)] ←→ [Gazebo 시뮬레이션]
                     │
                     └── 실기 전환 시: [실제 K20 제어 캐비닛] 으로 교체
```

### 설치

```bash
cd ~/ros2_ws/src/doosan-robot2 && bash install_emulator.sh
```

> Docker 이미지 `doosanrobot/dsr_emulator:3.0.1` (1.24GB)을 다운로드한다.

### 설치 확인

```bash
docker images | grep dsr_emulator
# doosanrobot/dsr_emulator   3.0.1   ...   1.24GB 가 출력되면 정상
```

### 설치 결과 (2026-03-03)
- doosanrobot/dsr_emulator:3.0.1 (1.24GB) 다운로드 완료

> **주의**: launch 파일이 자동으로 에뮬레이터를 관리하므로 수동으로 `docker run`할 필요 없음

---

## Step 10: ros-humble-ros-gz (Ignition Gazebo 브릿지)

### 이것은 무엇인가?
doosan-robot2는 Gazebo Classic(11.x)이 아닌 **Ignition Gazebo(Fortress)**를 사용한다.
`ros-humble-ros-gz`는 ROS2 ↔ Ignition Gazebo 간의 브릿지 패키지이다.

### 왜 필요한가?
- Step 3에서 설치한 `ros-humble-gazebo-ros-pkgs`는 Gazebo Classic용
- doosan-robot2의 launch 파일은 `ros_gz_sim` 패키지를 통해 Ignition Gazebo를 실행
- 이 패키지 없으면 `ros_gz_sim: not found` 에러 발생

### 설치

```bash
sudo apt install -y ros-humble-ros-gz
```

### 설치 결과 (2026-03-03)
- ros-humble-ros-gz 0.244.22 + 관련 패키지 6개 설치 완료

---

## Step 11: ign_ros2_control (Ignition ↔ ros2_control 브릿지)

### 이것은 무엇인가?
Ignition Gazebo 안에서 ros2_control 프레임워크를 사용하기 위한 플러그인이다.

### 왜 필요한가?
- Gazebo 시뮬레이션에서 로봇 관절을 ros2_control로 제어하려면 이 플러그인 필요
- 없으면 `Failed to load system plugin [ign_ros2_control-system]` 에러

### 설치

```bash
sudo apt install -y ros-humble-ign-ros2-control
```

### 설치 결과 (2026-03-03)
- ros-humble-ign-ros2-control 0.7.18 설치 완료

---

## Step 12: WSL2 렌더링 설정

### 왜 필요한가?
WSL2의 가상 GPU(WSLg)는 Ignition Gazebo의 기본 렌더링 엔진(Ogre2)이 요구하는
OpenGL 3.3+를 완전히 지원하지 않아 크래시가 발생한다.

### 설정

```bash
echo 'export IGN_GAZEBO_RENDER_ENGINE_GUI=ogre' >> ~/.bashrc
echo 'export IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre' >> ~/.bashrc
echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> ~/.bashrc
source ~/.bashrc
```

| 환경변수 | 값 | 설명 |
|----------|------|------|
| IGN_GAZEBO_RENDER_ENGINE_GUI | ogre | GUI 렌더링을 Ogre2 → Ogre1로 변경 |
| IGN_GAZEBO_RENDER_ENGINE_SERVER | ogre | 서버 렌더링을 Ogre2 → Ogre1로 변경 |
| LIBGL_ALWAYS_SOFTWARE | 1 | GPU 대신 CPU 소프트웨어 렌더링 사용 |

> 소프트웨어 렌더링이므로 프레임 레이트는 낮지만 (82% 실시간) 안정적으로 동작

### 설치 결과 (2026-03-03)
- ~/.bashrc에 3개 환경변수 추가 완료

---

## Step 13: Gazebo 시뮬레이션 첫 실행

### 실행 명령

```bash
ros2 launch dsr_bringup2 dsr_bringup2_gazebo.launch.py mode:=virtual host:=127.0.0.1 port:=12345 model:=m1013
```

### 주요 파라미터

| 파라미터 | 값 | 설명 |
|----------|------|------|
| mode | virtual / real | 에뮬레이터 모드 / 실기 모드 |
| host | 127.0.0.1 (가상) / 192.168.137.100 (실기) | DRCF 주소 |
| port | 12345 | 통신 포트 |
| model | m1013 | 로봇 모델명 |
| name | dsr01 | 로봇 네임스페이스 |

### 실행 확인 항목

| 항목 | 확인 내용 |
|------|----------|
| DRCF 연결 | `Connected to DRCF, STATE_STANDBY` 로그 출력 |
| Gazebo 창 | M1013 로봇 모델이 3D 뷰에 표시됨 |
| Entity Tree | ground_plane, sun, m1013 3개 항목 존재 |
| 컨트롤러 | joint_state_broadcaster, dsr_controller2 활성화 |

### 실행 결과 (2026-03-03)
- ✅ DRCF 에뮬레이터 자동 연결 성공 (DRCF version GF03020000)
- ✅ Gazebo 창에 M1013 6축 로봇 팔 모델 정상 표시
- ✅ 82.33% 실시간 속도로 시뮬레이션 동작 (소프트웨어 렌더링)

---

## 설치 요약 (2026-03-03 기준)

| Step | 구성요소 | 버전 | 상태 |
|------|----------|------|------|
| 1 | WSL2 + Ubuntu 22.04 | 22.04.5 LTS / Kernel 6.6.87.2 | ✅ 완료 |
| 2 | ROS2 Humble | humble | ✅ 완료 |
| 3 | Gazebo | 11.10.2 | ✅ 완료 |
| 4 | MoveIt2 | humble (30+ 패키지) | ✅ 완료 |
| 5 | ros2_control + 보조 도구 | humble (20+ 패키지) | ✅ 완료 |
| 6 | Docker | 28.2.2 | ✅ 완료 |
| 7 | rosdep + colcon | python3-rosdep2 / colcon-common-extensions | ✅ 완료 |
| 8 | doosan-robot2 | GitHub main (22 패키지) | ✅ 완료 |
| 9 | DRCF 에뮬레이터 | doosanrobot/dsr_emulator:3.0.1 | ✅ 완료 |
| 10 | ros-humble-ros-gz | 0.244.22 | ✅ 완료 |
| 11 | ros-humble-ign-ros2-control | 0.7.18 | ✅ 완료 |
| 12 | WSL2 렌더링 설정 | Ogre1 + SW렌더링 | ✅ 완료 |
| 13 | Gazebo 시뮬레이션 첫 실행 | M1013 성공 | ✅ 완료 |

---

## 트러블슈팅

설치 중 발생한 문제와 해결법은 `../../../knowledge-base/lessons-learned.md` 참조.

---

*이 문서는 2026-03-03에 작성되었으며, 설치 진행에 따라 업데이트됩니다.*
