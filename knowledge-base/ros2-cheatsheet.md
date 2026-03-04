# ROS2 명령어 치트시트

> 용어 인덱스: [glossary.md](glossary.md) | Gazebo: [gazebo-guide.md](gazebo-guide.md) | MoveIt2: [moveit2-guide.md](moveit2-guide.md)

---

## 기본 명령어

```bash
# 노드 목록
ros2 node list

# 토픽 목록
ros2 topic list

# 토픽 데이터 확인
ros2 topic echo /topic_name

# 서비스 목록
ros2 service list

# 파라미터 확인
ros2 param list
ros2 param get /node_name parameter_name
```

## 빌드 & 실행

```bash
# 워크스페이스 빌드
colcon build
colcon build --packages-select 패키지명

# 환경 설정
source install/setup.bash

# launch 파일 실행
ros2 launch 패키지명 launch파일.py
```

## URDF 관련

```bash
# URDF 문법 검증
check_urdf robot.urdf

# xacro → URDF 변환
xacro robot.urdf.xacro > robot.urdf

# joint_state_publisher_gui로 조인트 테스트
ros2 launch 패키지명 display.launch.py
```

## Gazebo 관련

```bash
# Gazebo 실행
ros2 launch gazebo_ros gazebo.launch.py

# 모델 스폰
ros2 run gazebo_ros spawn_entity.py -topic robot_description -entity robot_name
```

## MoveIt2 관련

```bash
# MoveIt2 Setup Assistant
ros2 launch moveit_setup_assistant setup_assistant.launch.py

# MoveIt2 실행
ros2 launch 패키지명_moveit_config demo.launch.py
```

## 디버깅

```bash
# TF 트리 확인
ros2 run tf2_tools view_frames

# rqt로 시각화
ros2 run rqt_graph rqt_graph
```
