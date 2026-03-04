# 교훈 & 노하우

> 용어 인덱스: [glossary.md](glossary.md) | Gazebo: [gazebo-guide.md](gazebo-guide.md) | MoveIt2: [moveit2-guide.md](moveit2-guide.md)

프로젝트 진행 중 축적되는 노하우를 기록한다.

---

<!-- 아래에 항목을 추가한다 -->
<!-- 형식:
## [날짜] 제목
- 상황:
- 해결:
- 교훈:
-->

## [2026-03-03] WSL2 터미널에서 멀티라인 명령어 문제
- 상황: `\` (백슬래시)로 줄바꿈한 멀티라인 명령어를 WSL2 터미널에 붙여넣기하면 Enter로 인해 명령이 중간에 실행됨
- 해결: 모든 명령어를 한 줄로 제공 (백슬래시 줄바꿈 사용 금지)
- 교훈: WSL2 사용자에게 명령어 제공 시 반드시 single-line 형태로 작성할 것

## [2026-03-03] ros2 --version 은 유효한 명령이 아님
- 상황: ROS2 설치 확인용으로 `ros2 --version` 명령어를 안내했으나 해당 옵션이 존재하지 않음
- 해결: `ros2 doctor --report` 또는 `ros2 topic list` 등으로 설치 확인
- 교훈: ROS2 설치 확인은 `ros2 doctor --report` 또는 `ros2 run demo_nodes_cpp talker` 사용

## [2026-03-03] rosdep, colcon 은 별도 설치 필요
- 상황: `rosdep install` 및 `colcon build` 실행 시 "command not found" 에러
- 해결: `sudo apt install -y python3-rosdep2 python3-colcon-common-extensions` 후 `sudo rosdep init && rosdep update`
- 교훈: ros-humble-desktop에 rosdep/colcon이 포함되지 않음. Step 4에 사전 설치 단계 추가 필요

## [2026-03-03] ros2 doctor --report | head 시 BrokenPipeError
- 상황: `ros2 doctor --report | head -20` 실행 시 BrokenPipeError 발생
- 해결: head가 파이프를 조기 종료해서 발생하는 외관상 에러. 데이터는 정상 출력됨
- 교훈: 파이프 앞의 프로그램이 출력 완료 전에 뒤의 프로그램이 종료되면 발생. 무시 가능

## [2026-03-03] DRCF 에뮬레이터 Docker 컨테이너 즉시 종료
- 상황: `docker run -d doosanrobot/dsr_emulator:3.0.1` 실행 시 컨테이너가 즉시 Exited(0)
- 해결: `-dit --privileged --env ROBOT_MODEL=M1013` 플래그 필요. `run_drcf.sh 12345 m1013` 스크립트 사용 권장
- 교훈: DRCF 에뮬레이터는 tty(-t), interactive(-i), privileged 모드, ROBOT_MODEL 환경변수가 모두 필요

## [2026-03-03] dsr_bringup2_gazebo.launch.py는 DRCF 에뮬레이터를 자동 시작
- 상황: 수동으로 DRCF 에뮬레이터를 시작한 뒤 launch 실행 시 포트 충돌 (12345 already allocated)
- 해결: `mode:=virtual`로 실행하면 launch 파일이 자동으로 에뮬레이터 컨테이너를 시작/정리함
- 교훈: 수동으로 에뮬레이터를 시작할 필요 없음. 중복 실행 시 포트 충돌 발생

## [2026-03-03] doosan-robot2는 Ignition Gazebo(Fortress) 사용 — Gazebo Classic이 아님
- 상황: `ros-humble-gazebo-ros-pkgs`만 설치하면 `ros_gz_sim` 패키지 미발견 에러 발생
- 해결: `sudo apt install -y ros-humble-ros-gz` 로 Ignition Gazebo ↔ ROS2 브릿지 설치
- 교훈: doosan-robot2는 Gazebo Classic(11.x)이 아닌 Ignition Gazebo(Fortress)를 사용. ros-humble-ros-gz 필수

## [2026-03-03] WSL2에서 Ogre2 렌더링 크래시
- 상황: Ignition Gazebo 실행 시 `OGRE EXCEPTION(9:UnimplementedException): GL3PlusTextureGpu::copyTo` 크래시
- 해결: 환경변수 3개 설정으로 해결
  - `export IGN_GAZEBO_RENDER_ENGINE_GUI=ogre` (Ogre2 → Ogre1)
  - `export IGN_GAZEBO_RENDER_ENGINE_SERVER=ogre`
  - `export LIBGL_ALWAYS_SOFTWARE=1` (소프트웨어 렌더링)
- 교훈: WSL2의 가상 GPU(WSLg)는 Ogre2의 OpenGL 3.3+를 완전히 지원하지 않음. Ogre1 + SW렌더링 조합 필수

## [2026-03-03] ign_ros2_control 플러그인 누락
- 상황: `Failed to load system plugin [ign_ros2_control-system]` 에러
- 해결: `sudo apt install -y ros-humble-ign-ros2-control`
- 교훈: Ignition Gazebo에서 ros2_control을 사용하려면 별도의 브릿지 패키지가 필요

## [2026-03-04] Claude Code 스킬은 .claude/skills/ 에만 인식됨
- 상황: root `skills/` 디렉토리에 SKILL.md를 배치했으나 `/skill-name` 슬래시 커맨드로 인식되지 않음
- 해결: `.claude/skills/{skill-name}/SKILL.md`로 이동. frontmatter의 `name` 필드가 커맨드 이름이 됨
- 교훈: Claude Code는 `.claude/skills/` 경로만 스캔. 새 세션에서만 인식됨 (현재 세션 중 추가 시 미반영)

## [2026-03-04] Doosan MoveIt2 — Planning Group 이름은 'manipulator'
- 상황: MoveGroup 액션에서 `group_name='arm'`으로 요청 시 에러코드 99999
- 해결: SRDF(`dsr_moveit_config_m1013/config/dsr.srdf`) 확인 → `group_name='manipulator'`
- 교훈: MoveIt2 planning group 이름은 반드시 SRDF를 확인할 것. 관절 이름도 `joint_1` (언더스코어 포함)

## [2026-03-04] Doosan MoveIt2 — /execute_trajectory 대신 FollowJointTrajectory 사용
- 상황: `/execute_trajectory` 액션으로 실행 시 타임아웃(-7) 또는 CONTROL_FAILED(-4) 에러
- 해결: `/dsr_moveit_controller/follow_joint_trajectory`에 직접 `FollowJointTrajectory` 전송
- 교훈: Plan(`/plan_kinematic_path`) → Execute(`FollowJointTrajectory`) 분리 패턴이 Doosan 드라이버와 호환됨. MoveIt2 기본 실행 경로는 Doosan 컨트롤러와 충돌할 수 있음
