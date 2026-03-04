#!/bin/bash
# =============================================================================
# Robot Simulation Platform — 전체 자동 설치 스크립트
# =============================================================================
# 용도: WSL2 Ubuntu 22.04에서 ROS2 + Gazebo + MoveIt2 + Doosan 패키지를
#       한 번에 설치하고 시뮬레이션 실행 가능 상태까지 구성한다.
#
# 사용법:
#   bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/install-all.sh
#
# 전제조건:
#   - WSL2 + Ubuntu 22.04 설치 완료
#   - sudo 비밀번호 없이 실행 가능 (NOPASSWD 설정)
#     설정 방법: echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
#
# 소요시간: 약 20~40분 (네트워크 속도에 따라 다름)
# =============================================================================

set -e  # 에러 발생 시 즉시 중단

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  Step $1: $2${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_ok() {
    echo -e "${GREEN}[OK] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 전제조건 확인
check_prerequisites() {
    echo -e "${BLUE}전제조건 확인 중...${NC}"

    # Ubuntu 22.04 확인
    if ! grep -q "22.04" /etc/os-release 2>/dev/null; then
        log_error "Ubuntu 22.04가 아닙니다. 이 스크립트는 Ubuntu 22.04 전용입니다."
        exit 1
    fi
    log_ok "Ubuntu 22.04 확인"

    # sudo NOPASSWD 확인
    if ! sudo -n true 2>/dev/null; then
        log_error "sudo 비밀번호 없이 실행할 수 없습니다."
        echo "아래 명령을 먼저 실행하세요 (비밀번호 한 번 입력 필요):"
        echo '  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER'
        exit 1
    fi
    log_ok "sudo NOPASSWD 확인"

    # 인터넷 연결 확인
    if ! ping -c 1 -W 3 packages.ros.org > /dev/null 2>&1; then
        log_warn "packages.ros.org에 연결할 수 없습니다. 네트워크를 확인하세요."
    else
        log_ok "네트워크 연결 확인"
    fi
}

# ─── Step 1: 시스템 업데이트 ─────────────────────────────────────
step1_system_update() {
    log_step 1 "시스템 업데이트"
    sudo apt update && sudo apt upgrade -y
    log_ok "시스템 업데이트 완료"
}

# ─── Step 2: ROS2 Humble 설치 ───────────────────────────────────
step2_ros2() {
    log_step 2 "ROS2 Humble 설치"

    # 이미 설치되어 있는지 확인
    if dpkg -l ros-humble-desktop 2>/dev/null | grep -q "^ii"; then
        log_warn "ROS2 Humble이 이미 설치되어 있습니다. 건너뜁니다."
        return 0
    fi

    sudo apt install -y software-properties-common
    sudo add-apt-repository -y universe
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    sudo apt update
    sudo apt install -y ros-humble-desktop

    # bashrc에 source 추가 (중복 방지)
    grep -q 'source /opt/ros/humble/setup.bash' ~/.bashrc || echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

    log_ok "ROS2 Humble 설치 완료"
}

# ─── Step 3: Gazebo + MoveIt2 + ros2_control ─────────────────────
step3_gazebo_moveit() {
    log_step 3 "Gazebo + MoveIt2 + ros2_control 설치"
    sudo apt install -y \
        ros-humble-gazebo-ros-pkgs \
        ros-humble-moveit \
        ros-humble-joint-state-publisher-gui \
        ros-humble-xacro \
        ros-humble-ros2-control \
        ros-humble-ros2-controllers
    log_ok "Gazebo + MoveIt2 + ros2_control 설치 완료"
}

# ─── Step 4: Ignition Gazebo 브릿지 ──────────────────────────────
step4_ignition_bridge() {
    log_step 4 "Ignition Gazebo 브릿지 + ign_ros2_control 설치"
    sudo apt install -y ros-humble-ros-gz ros-humble-ign-ros2-control
    log_ok "Ignition Gazebo 브릿지 설치 완료"
}

# ─── Step 5: 빌드 도구 (rosdep + colcon) ──────────────────────────
step5_build_tools() {
    log_step 5 "빌드 도구 설치 (rosdep + colcon)"
    sudo apt install -y python3-rosdep2 python3-colcon-common-extensions

    # rosdep init (이미 초기화된 경우 무시)
    sudo rosdep init 2>/dev/null || true
    rosdep update

    log_ok "빌드 도구 설치 완료"
}

# ─── Step 6: Docker ──────────────────────────────────────────────
step6_docker() {
    log_step 6 "Docker 설치"

    if command -v docker &> /dev/null; then
        log_warn "Docker가 이미 설치되어 있습니다."
    else
        sudo apt install -y docker.io
    fi

    # docker 그룹에 사용자 추가
    if ! groups | grep -q docker; then
        sudo usermod -aG docker $USER
        log_warn "docker 그룹에 추가되었습니다. 이 스크립트에서는 sudo docker를 사용합니다."
    fi

    log_ok "Docker 설치 완료"
}

# ─── Step 7: Doosan doosan-robot2 패키지 ──────────────────────────
step7_doosan_package() {
    log_step 7 "Doosan doosan-robot2 패키지 빌드"

    source /opt/ros/humble/setup.bash

    mkdir -p ~/ros2_ws/src

    # 이미 클론되어 있는지 확인
    if [ -d ~/ros2_ws/src/doosan-robot2 ]; then
        log_warn "doosan-robot2가 이미 존재합니다. pull로 업데이트합니다."
        cd ~/ros2_ws/src/doosan-robot2 && git pull || true
    else
        cd ~/ros2_ws/src && git clone https://github.com/doosan-robotics/doosan-robot2.git
    fi

    # 의존성 설치 + 빌드
    cd ~/ros2_ws && rosdep install --from-paths src --ignore-src -r -y
    cd ~/ros2_ws && colcon build

    # bashrc에 source 추가 (중복 방지)
    grep -q 'source ~/ros2_ws/install/setup.bash' ~/.bashrc || echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc

    log_ok "Doosan 패키지 빌드 완료"
}

# ─── Step 8: DRCF 에뮬레이터 Docker 이미지 ────────────────────────
step8_drcf_emulator() {
    log_step 8 "DRCF 에뮬레이터 Docker 이미지 다운로드"

    # 이미 다운로드되어 있는지 확인
    if sudo docker images | grep -q dsr_emulator; then
        log_warn "DRCF 에뮬레이터 이미지가 이미 존재합니다."
    else
        cd ~/ros2_ws/src/doosan-robot2 && bash install_emulator.sh
    fi

    log_ok "DRCF 에뮬레이터 준비 완료"
}

# ─── Step 9: WSL2 렌더링 환경변수 ─────────────────────────────────
step9_render_settings() {
    log_step 9 "WSL2 렌더링 환경변수 설정"

    grep -q 'IGN_GAZEBO_RENDER_ENGINE_GUI' ~/.bashrc || echo 'export IGN_GAZEBO_RENDER_ENGINE_GUI=ogre' >> ~/.bashrc
    grep -q 'IGN_GAZEBO_RENDER_ENGINE_SERVER' ~/.bashrc || echo 'export IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre' >> ~/.bashrc
    grep -q 'LIBGL_ALWAYS_SOFTWARE' ~/.bashrc || echo 'export LIBGL_ALWAYS_SOFTWARE=1' >> ~/.bashrc

    log_ok "렌더링 환경변수 설정 완료"
}

# ─── 검증 ─────────────────────────────────────────────────────────
verify_installation() {
    log_step "✓" "설치 검증"

    source ~/.bashrc 2>/dev/null || true
    source /opt/ros/humble/setup.bash
    source ~/ros2_ws/install/setup.bash 2>/dev/null || true

    echo "--- ROS2 패키지 확인 ---"
    ros2 pkg list 2>/dev/null | grep -c dsr | xargs -I{} echo "Doosan 패키지: {} 개"

    echo "--- Docker 이미지 확인 ---"
    sudo docker images | grep dsr_emulator || log_warn "DRCF 에뮬레이터 이미지를 찾을 수 없습니다."

    echo "--- 렌더링 설정 확인 ---"
    grep -E 'LIBGL|IGN_GAZEBO' ~/.bashrc

    log_ok "설치 검증 완료"
}

# ─── 메인 실행 ────────────────────────────────────────────────────
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  Robot Simulation Platform — 자동 설치 스크립트         ║"
    echo "║  ROS2 Humble + Ignition Gazebo + MoveIt2 + Doosan      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_prerequisites

    step1_system_update
    step2_ros2
    step3_gazebo_moveit
    step4_ignition_bridge
    step5_build_tools
    step6_docker
    step7_doosan_package
    step8_drcf_emulator
    step9_render_settings
    verify_installation

    echo -e "\n${GREEN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  설치 완료!                                             ║"
    echo "║                                                        ║"
    echo "║  시뮬레이션 실행:                                       ║"
    echo "║  ros2 launch dsr_bringup2 dsr_bringup2_gazebo.launch.py ║"
    echo "║    mode:=virtual host:=127.0.0.1 port:=12345            ║"
    echo "║    model:=m1013                                         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 실행
main "$@"
