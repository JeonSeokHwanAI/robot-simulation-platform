#!/bin/bash
# 로봇 태스크 실행 스크립트
#
# 사용법:
#   bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/run-task.sh [로봇] [태스크]
#
# 예시:
#   bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/run-task.sh doosan-m1013 pick_and_load
#   bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/run-task.sh              # 대화형 선택

PROJ_ROOT="/mnt/e/WorkSpace/robot-simulation-platform"
TASKS_BASE="${PROJ_ROOT}/robots"

# ROS2 환경 로드
source ~/ros2_ws/install/setup.bash 2>/dev/null || {
    echo "[ERROR] ROS2 워크스페이스를 찾을 수 없습니다. 먼저 빌드하세요."
    exit 1
}

# ── 로봇 선택 ──────────────────────────────────────
list_robots() {
    for d in "${TASKS_BASE}"/*/tasks; do
        [ -d "$d" ] && basename "$(dirname "$d")"
    done
}

if [ -n "$1" ]; then
    ROBOT="$1"
else
    echo ""
    echo "=== 로봇 선택 ==="
    robots=($(list_robots))
    if [ ${#robots[@]} -eq 0 ]; then
        echo "[ERROR] 등록된 태스크가 없습니다."
        exit 1
    fi
    for i in "${!robots[@]}"; do
        echo "  $((i+1)). ${robots[$i]}"
    done
    echo ""
    read -rp "번호 선택: " choice
    ROBOT="${robots[$((choice-1))]}"
fi

TASK_DIR="${TASKS_BASE}/${ROBOT}/tasks"
if [ ! -d "$TASK_DIR" ]; then
    echo "[ERROR] 태스크 디렉토리 없음: ${TASK_DIR}"
    exit 1
fi

# ── 태스크 선택 ──────────────────────────────────────
list_tasks() {
    for f in "${TASK_DIR}"/*.py; do
        [ -f "$f" ] && basename "$f" .py
    done
}

if [ -n "$2" ]; then
    TASK="$2"
else
    echo ""
    echo "=== 태스크 선택 (${ROBOT}) ==="
    tasks=($(list_tasks))
    if [ ${#tasks[@]} -eq 0 ]; then
        echo "[ERROR] ${ROBOT}에 등록된 태스크가 없습니다."
        exit 1
    fi
    for i in "${!tasks[@]}"; do
        # 스크립트 첫 번째 docstring에서 설명 추출
        desc=$(sed -n '3p' "${TASK_DIR}/${tasks[$i]}.py" 2>/dev/null)
        echo "  $((i+1)). ${tasks[$i]}  — ${desc}"
    done
    echo ""
    read -rp "번호 선택: " choice
    TASK="${tasks[$((choice-1))]}"
fi

TASK_FILE="${TASK_DIR}/${TASK}.py"
if [ ! -f "$TASK_FILE" ]; then
    echo "[ERROR] 태스크 파일 없음: ${TASK_FILE}"
    exit 1
fi

# ── 실행 ──────────────────────────────────────────
echo ""
echo "=================================================="
echo "  로봇: ${ROBOT}"
echo "  태스크: ${TASK}"
echo "  파일: ${TASK_FILE}"
echo "=================================================="
echo ""

python3 "$TASK_FILE"
