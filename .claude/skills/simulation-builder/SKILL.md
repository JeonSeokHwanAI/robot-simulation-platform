---
name: simulation-builder
description: "Gazebo 시뮬레이션 월드를 구성하는 스킬. 로봇 배치, 작업대, 컨베이어, 공작물 등 환경 요소를 배치하고 시뮬레이션 월드 파일을 생성한다. 'Gazebo 월드', '시뮬레이션 환경', '작업대 배치', '레이아웃', '월드 파일', 'SDF', '환경 구성' 등의 요청에 트리거."
---

# Gazebo 시뮬레이션 월드 구성 가이드

## 개요
로봇 시뮬레이션을 위한 Gazebo 월드를 구성한다.
작업대, 공작물, 센서 등 환경 요소를 배치하고 시뮬레이션 월드 파일을 생성.

## 월드 구성 요소

### 필수
- 바닥면 (ground plane)
- 로봇 모델 (URDF → Gazebo 스폰)
- 조명 (sun)

### 작업 환경
- 작업대 (worktable)
- 공작물 (workpiece)
- 컨베이어 벨트
- 도구/그리퍼
- 안전 펜스

## 월드 파일 구조

```xml
<?xml version="1.0"?>
<sdf version="1.6">
  <world name="robot_workspace">
    <!-- 조명 -->
    <include><uri>model://sun</uri></include>
    <!-- 바닥 -->
    <include><uri>model://ground_plane</uri></include>

    <!-- 작업대 -->
    <model name="worktable">
      <!-- 크기, 위치 정의 -->
    </model>

    <!-- 공작물 -->
    <model name="workpiece">
      <!-- 크기, 위치, 물리 속성 정의 -->
    </model>
  </world>
</sdf>
```

## Launch 파일 작성

```python
# gazebo.launch.py 예시
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # Gazebo 서버 + 클라이언트
        # 로봇 스폰
        # 컨트롤러 로드
    ])
```

## 작업별 레이아웃 예시

### Machine Tending (공작기계 로딩/언로딩)
```
[CNC 기계] ← 1m → [로봇] ← 0.5m → [소재 트레이]
```

### Pick & Place
```
[소스 팔레트] ← [로봇] → [타겟 팔레트]
```

## 결과물
- `{project}/world/` 폴더에 .world 또는 .sdf 파일 저장
- `{project}/launch/` 폴더에 launch 파일 저장
