---
name: simulation-launch
description: "시뮬레이션 실행. Gazebo 런치, MoveIt2 런치, 로봇 시뮬레이션 시작, 실행, 구동"
---

# 시뮬레이션 실행

## 개요

보유 로봇의 시뮬레이션을 선택하여 실행하는 스킬.
로봇과 모드를 선택하면 Claude가 WSL2에서 직접 런치한다.

---

## 실행 절차

### Step 1: 로봇 선택

AskUserQuestion으로 보유 로봇 목록을 표시한다:

| # | 로봇 | 상태 |
|---|------|------|
| 1 | Doosan M1013 | ✅ 실행 가능 |
| 2 | CGXI R12 | ⚠️ URDF 미완성 → `/robot-onboarding` 먼저 실행 |

### Step 2: 실행 모드 선택

AskUserQuestion으로 모드를 표시한다:

| # | 모드 | 설명 | 용도 |
|---|------|------|------|
| 1 | Gazebo | 3D 물리 시뮬레이션 (Ignition Fortress) | 환경 검증, 충돌 테스트 |
| 2 | MoveIt2 | 모션 플래닝 (RViz, FakeSystem) | 경로 계획, 관절 제어 |
| 3 | Gazebo + MoveIt2 | 물리 시뮬레이션 + 모션 플래닝 | 통합 시뮬레이션 |

### Step 3: 사전 조건 확인

실행 전 아래를 자동으로 확인한다:

```bash
# 1. WSL2 접근
wsl -d Ubuntu-22.04 -- bash -lc "echo OK"

# 2. Docker 상태 (Gazebo 모드 시)
wsl -d Ubuntu-22.04 -- bash -lc "docker info > /dev/null 2>&1 && echo OK || echo FAIL"

# 3. 렌더링 환경변수 확인 (Gazebo 모드 시)
wsl -d Ubuntu-22.04 -- bash -lc "echo IGN_GUI=\$IGN_GAZEBO_RENDER_ENGINE_GUI IGN_SRV=\$IGN_GAZEBO_RENDER_ENGINE_SERVER LIBGL=\$LIBGL_ALWAYS_SOFTWARE"

# 4. ROS2 워크스페이스 확인
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && echo OK"
```

실패 시 → `/environment-setup`으로 안내한다.

### Step 4: 실행

선택된 로봇+모드에 따라 아래 명령을 실행한다.

---

## 로봇별 런치 명령

### Doosan M1013

#### Gazebo 모드

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && ros2 launch dsr_bringup2 dsr_bringup2_gazebo.launch.py mode:=virtual host:=127.0.0.1 port:=12345 model:=m1013"
```

- DRCF 에뮬레이터 자동 시작 (수동 Docker 불필요)
- timeout: 600000 (10분) — 장시간 실행
- run_in_background: true — 백그라운드 실행

#### MoveIt2 모드

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && ros2 launch dsr_bringup2 dsr_bringup2_moveit.launch.py mode:=virtual host:=127.0.0.1 port:=12345 model:=m1013"
```

- FakeSystem 사용 (물리 엔진 없음)
- RViz에서 인터랙티브 마커로 목표 자세 설정 가능
- 플래너: OMPL / CHOMP / Pilz 선택 가능

#### Gazebo + MoveIt2 모드

통합 런치 파일 하나로 실행한다 (DRCF 에뮬레이터 불필요):

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && ros2 launch dsr_bringup2 dsr_bringup2_gazebo_moveit.launch.py model:=m1013"
```

- gz_ros2_control이 유일한 controller_manager (포트 충돌 없음)
- ros_gz_bridge로 /clock 자동 브릿지
- RViz 네임스페이스 자동 패치 (/sim)
- timeout: 600000, run_in_background: true

##### 태스크 실행 (Gazebo + MoveIt2 가동 중일 때)

시뮬레이션 가동 후, 저장된 태스크를 불러와 실행한다:

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && python3 /mnt/e/WorkSpace/robot-simulation-platform/robots/doosan-m1013/tasks/pick_and_load.py"
```

또는 태스크 런처를 사용한다:
```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/run-task.sh doosan-m1013 pick_and_load"
```

등록된 태스크 목록: `robots/doosan-m1013/tasks/` 디렉토리의 `.py` 파일들

### CGXI R12

> ⚠️ URDF가 아직 완성되지 않았습니다.
> `/robot-onboarding`을 먼저 실행하여 URDF를 제작하세요.
> 참조: `robots/cgxi-r12/README.md`

---

## 렌더링 필수 환경변수

Gazebo 모드 실행 시 `.bashrc`에 아래가 설정되어 있어야 한다:

```bash
export IGN_GAZEBO_RENDER_ENGINE_GUI=ogre
export IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre
export LIBGL_ALWAYS_SOFTWARE=1
```

미설정 시 Claude가 자동으로 추가한다:

```bash
wsl -d Ubuntu-22.04 -- bash -lc "grep -q 'IGN_GAZEBO_RENDER_ENGINE_GUI' ~/.bashrc || echo -e '\nexport IGN_GAZEBO_RENDER_ENGINE_GUI=ogre\nexport IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre\nexport LIBGL_ALWAYS_SOFTWARE=1' >> ~/.bashrc"
```

---

## 종료 방법

- 시뮬레이션 종료는 사용자에게 Ctrl+C 안내
- 또는 Claude가 프로세스를 종료:
```bash
wsl -d Ubuntu-22.04 -- bash -lc "pkill -f 'ros2 launch'"
```

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 포트 12345 충돌 | DRCF 컨테이너 중복 실행 | `docker ps`로 확인 → `docker stop` |
| Ogre2 크래시 | WSL2 GPU 호환성 | 렌더링 환경변수 확인 |
| controller_manager 타임아웃 | 빌드 누락 또는 순서 문제 | `colcon build` 재실행 |
| Docker 미실행 | Docker Desktop 미시작 | Windows에서 Docker Desktop 실행 |

상세 트러블슈팅: `knowledge-base/lessons-learned.md`
