---
name: environment-setup
description: "WSL2 + ROS2 Humble + Gazebo Fortress + MoveIt2 환경 구축 스킬. 'WSL 설치', 'ROS2 설치', 'Gazebo 설치', '환경 구축', '환경 설정', '시뮬레이션 환경', '빌드 에러', '의존성 문제' 등의 요청에 트리거."
---

# 시뮬레이션 환경 구축 스킬

## 개요
Windows 10 + WSL2 환경에서 ROS2 Humble + Ignition Gazebo Fortress + MoveIt2를
설치하고 Doosan M1013 시뮬레이션까지 실행하는 스킬.

**두 가지 모드**를 지원한다:
- **자동 모드**: Claude가 WSL2 터미널에서 직접 명령어를 실행 (권장)
- **가이드 모드**: 사용자에게 명령어를 안내하고 사용자가 직접 실행

## 환경 스택

```
Windows 10 (Host)
└── WSL2 (Ubuntu 22.04 Jammy)
    ├── ROS2 Humble Hawksbill
    ├── Ignition Gazebo Fortress (ros-humble-ros-gz)
    ├── MoveIt2 (Humble 호환)
    ├── ros2_control + ign_ros2_control
    └── Docker (Doosan DRCF 에뮬레이터용)
```

---

## 자동 모드 (Claude 직접 실행)

### 전제조건 (사용자가 직접 수행)

Claude는 아래 3단계를 사용자에게 **가이드**로 안내한다:

#### 1단계: WSL2 + Ubuntu 설치 (PowerShell 관리자 권한)
```powershell
wsl --install -d Ubuntu-22.04
```
> 재부팅 필요. 재부팅 후 Ubuntu 터미널이 자동 실행되면 사용자명/비밀번호 설정.

#### 2단계: Claude가 WSL2에 접근 가능한지 확인
Claude가 다음 명령으로 확인:
```
wsl -d Ubuntu-22.04 -- bash -lc "echo OK"
```

#### 3단계: sudo 비밀번호 없이 실행 가능하게 설정
사용자에게 WSL2 터미널에서 아래 명령어 실행을 안내:
```bash
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
```
> 이 명령에서만 비밀번호 입력 필요. 이후 모든 sudo 명령이 비밀번호 없이 동작.

### 자동 실행 절차

전제조건 완료 후, Claude는 아래 명령어들을 `wsl -d Ubuntu-22.04 -- bash -lc "명령어"` 형태로 **직접 실행**한다.

#### Step 1: 시스템 업데이트
```bash
sudo apt update && sudo apt upgrade -y
```

#### Step 2: ROS2 Humble 설치
```bash
sudo apt install -y software-properties-common
sudo add-apt-repository -y universe
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt install -y ros-humble-desktop
```
bashrc 추가:
```bash
grep -q 'source /opt/ros/humble/setup.bash' ~/.bashrc || echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
```

#### Step 3: Gazebo + MoveIt2 + ros2_control
```bash
sudo apt install -y ros-humble-gazebo-ros-pkgs ros-humble-moveit ros-humble-joint-state-publisher-gui ros-humble-xacro ros-humble-ros2-control ros-humble-ros2-controllers
```

#### Step 4: Ignition Gazebo 브릿지 + ign_ros2_control
```bash
sudo apt install -y ros-humble-ros-gz ros-humble-ign-ros2-control
```

#### Step 5: 빌드 도구 (rosdep + colcon)
```bash
sudo apt install -y python3-rosdep2 python3-colcon-common-extensions
sudo rosdep init 2>/dev/null; rosdep update
```

#### Step 6: Docker
```bash
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```
> docker 그룹 적용을 위해 `newgrp docker` 또는 WSL 재시작 필요

#### Step 7: Doosan doosan-robot2 패키지
```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src && git clone https://github.com/doosan-robotics/doosan-robot2.git
cd ~/ros2_ws && source /opt/ros/humble/setup.bash && rosdep install --from-paths src --ignore-src -r -y
cd ~/ros2_ws && source /opt/ros/humble/setup.bash && colcon build
```
bashrc 추가:
```bash
grep -q 'source ~/ros2_ws/install/setup.bash' ~/.bashrc || echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc
```

#### Step 8: DRCF 에뮬레이터 Docker 이미지
```bash
cd ~/ros2_ws/src/doosan-robot2 && bash install_emulator.sh
```

#### Step 9: WSL2 렌더링 환경변수
```bash
grep -q 'IGN_GAZEBO_RENDER_ENGINE_GUI' ~/.bashrc || echo 'export IGN_GAZEBO_RENDER_ENGINE_GUI=ogre' >> ~/.bashrc
grep -q 'IGN_GAZEBO_RENDER_ENGINE_SERVER' ~/.bashrc || echo 'export IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre' >> ~/.bashrc
grep -q 'LIBGL_ALWAYS_SOFTWARE' ~/.bashrc || echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> ~/.bashrc
```

#### Step 10: 검증
```bash
source ~/.bashrc
ros2 topic list
docker images | grep dsr_emulator
```

#### Step 11: Gazebo 시뮬레이션 실행
```bash
ros2 launch dsr_bringup2 dsr_bringup2_gazebo.launch.py mode:=virtual host:=127.0.0.1 port:=12345 model:=m1013
```

### 자동 실행 시 주의사항

1. **타임아웃**: `sudo apt install`과 `colcon build`는 시간이 오래 걸릴 수 있음 (timeout 600000ms 권장)
2. **멱등성**: 모든 명령은 이미 설치된 환경에서 재실행해도 안전하게 설계됨 (`grep -q`로 중복 추가 방지)
3. **에러 처리**: 각 Step 실행 후 exit code 확인. 실패 시 `knowledge-base/lessons-learned.md` 참조
4. **WSL 명령 형식**: `wsl -d Ubuntu-22.04 -- bash -lc "명령어"` (bash -l로 .bashrc 로드)
5. **long-running 명령**: `colcon build`, `apt install` 등은 백그라운드로 실행하고 TaskOutput으로 확인

---

## 가이드 모드 (사용자 직접 실행)

사용자가 직접 터미널에서 실행할 경우, `knowledge-base/installation-guide.md`의
Step 1~13을 순서대로 안내한다.

### 안내 규칙
- 모든 명령어는 **한 줄**로 제공 (WSL2 터미널에서 `\` 줄바꿈 문제 방지)
- 각 Step 완료 후 검증 명령어를 함께 안내
- 에러 발생 시 `knowledge-base/lessons-learned.md` 참조

---

## 백업 스크립트

전체 설치를 자동화하는 쉘 스크립트: `scripts/install-all.sh`

```bash
# WSL2 Ubuntu 터미널에서 실행
cd ~/ros2_ws/src/doosan-robot2/../../.. && bash scripts/install-all.sh
# 또는 프로젝트 폴더에서
bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/install-all.sh
```

---

## 트러블슈팅

자주 발생하는 에러와 해결법은 아래 참조:
- `knowledge-base/lessons-learned.md` — 실전 경험 기반 해결법
- `references/troubleshooting.md` — 일반적인 트러블슈팅
