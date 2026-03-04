#!/bin/bash
# 커스텀 런치/설정 파일을 WSL2 ros2_ws로 배포하는 스크립트
# 사용법: bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/deploy-custom-files.sh

set -e

PROJ_DIR="/mnt/e/WorkSpace/robot-simulation-platform"
ROS2_WS="$HOME/ros2_ws"
DOOSAN_PKG="$ROS2_WS/src/doosan-robot2"

echo "=== 커스텀 파일 배포 ==="

# doosan-robot2 패키지 존재 확인
if [ ! -d "$DOOSAN_PKG" ]; then
    echo "[ERROR] doosan-robot2 패키지를 찾을 수 없습니다: $DOOSAN_PKG"
    echo "먼저 /environment-setup 또는 install-all.sh를 실행하세요."
    exit 1
fi

# 1. 통합 런치 파일
cp "$PROJ_DIR/robots/doosan-m1013/launch/dsr_bringup2_gazebo_moveit.launch.py" \
   "$DOOSAN_PKG/dsr_bringup2/launch/"
echo "[OK] 통합 런치 파일 배포 완료"

# 2. Gazebo 컨트롤러 설정
cp "$PROJ_DIR/robots/doosan-m1013/config/dsr_controller2_gz.yaml" \
   "$DOOSAN_PKG/dsr_controller2/config/"
echo "[OK] Gazebo 컨트롤러 설정 배포 완료"

# 3. MoveIt 전용 Gazebo 월드 파일
cp "$PROJ_DIR/robots/doosan-m1013/worlds/m1013_moveit.sdf" \
   "$DOOSAN_PKG/dsr_bringup2/worlds/"
echo "[OK] Gazebo 월드 파일 배포 완료"

# 4. colcon build (변경된 패키지만)
echo ""
echo "=== colcon build (dsr_bringup2, dsr_controller2) ==="
cd "$ROS2_WS"
source /opt/ros/humble/setup.bash
colcon build --packages-select dsr_bringup2 dsr_controller2
source "$ROS2_WS/install/setup.bash"

echo ""
echo "=== 배포 완료 ==="
echo "이제 아래 명령으로 시뮬레이션을 실행할 수 있습니다:"
echo "  ros2 launch dsr_bringup2 dsr_bringup2_gazebo_moveit.launch.py model:=m1013"
