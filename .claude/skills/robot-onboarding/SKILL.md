---
name: robot-onboarding
description: "새로운 로봇을 시뮬레이션 플랫폼에 추가하는 스킬. 3D 파일에서 URDF 변환, 기구학 파라미터 설정, Gazebo 연동, MoveIt2 설정까지 전체 온보딩 과정을 안내한다. '새 로봇 추가', 'URDF 만들기', '3D 모델 변환', 'STEP to URDF', '로봇 등록', 'MoveIt2 설정', '기구학', 'DH 파라미터', '새 로봇 시뮬레이션' 등의 요청에 트리거. ROS2 공식 패키지가 없는 로봇(CGXI 등)을 시뮬레이션하려 할 때 반드시 이 스킬을 사용한다."
---

# 로봇 온보딩 가이드

## 개요
ROS2/Gazebo 공식 패키지가 없는 로봇을 시뮬레이션 플랫폼에 추가하는 절차.
3D 파일과 매뉴얼 사양을 기반으로 URDF를 제작하고 Gazebo + MoveIt2에서
동작할 수 있도록 설정한다.

## 온보딩 전체 흐름

```
1. 로봇 프로필 생성 (robots/{robot-name}/)
2. 벤더 데이터 수집 (매뉴얼, 3D 파일, 엔지니어 확인)
3. 3D 메쉬 변환 (STEP/IGES → STL/DAE)
4. URDF 작성 (링크 + 조인트 정의)
5. Gazebo 표시 테스트 (정적 모델)
6. 조인트 제어 테스트 (동적 모델)
7. MoveIt2 설정 (모션 플래닝)
8. 검증 및 등록 완료
```

## Step 1: 로봇 프로필 생성

새 로봇을 추가할 때 아래 디렉토리를 생성한다:

```
robots/{robot-name}/
├── README.md          # 로봇 사양서 (아래 양식)
├── urdf/
│   └── {robot}.urdf.xacro   # URDF 모델
├── meshes/
│   ├── visual/        # 시각용 메쉬 (DAE/STL, 디테일 있음)
│   └── collision/     # 충돌용 메쉬 (STL, 단순화)
├── config/
│   ├── joint_limits.yaml
│   ├── kinematics.yaml
│   └── controllers.yaml
└── vendor-docs/       # 벤더 제공 원본 자료 보관
```

## Step 2: 벤더 데이터 수집

### 필수 데이터 (시뮬레이션에 반드시 필요)

| 데이터 | 용도 | 확인 방법 |
|--------|------|-----------|
| 각 축(J1~J6) 동작 범위 | URDF 조인트 제한 | 매뉴얼 사양표 |
| 각 축 간 링크 길이 (mm) | URDF 링크 정의 | 매뉴얼 치수도면 또는 DH 파라미터 |
| 각 축 최대 속도 (°/s) | 조인트 속도 제한 | 매뉴얼 사양표 |
| 3D 모델 파일 | Gazebo 시각화 | STEP, IGES, STL 등 |
| 로봇 자중 (kg) | 관성 계산 | 매뉴얼 사양표 |
| TCP 기본 위치/방향 | 엔드이펙터 기준점 | 매뉴얼 좌표계 설명 |

### 권장 데이터 (있으면 정밀도 향상)

| 데이터 | 용도 | 확인 방법 |
|--------|------|-----------|
| DH 파라미터 (a, d, α, θ) | 정확한 기구학 모델 | 매뉴얼 또는 엔지니어 |
| 각 링크 질량 | 정확한 동역학 시뮬레이션 | 엔지니어 문의 |
| 각 링크 무게중심 | 동역학 정밀도 | 엔지니어 문의 |
| 각 링크 관성 모멘트 | 동역학 정밀도 | 엔지니어 문의 |
| 감속비 | 토크 계산 | 엔지니어 문의 |

### 연동 관련 데이터 (실제 로봇 연결 시 필요)

| 데이터 | 용도 | 확인 방법 |
|--------|------|-----------|
| 통신 프로토콜 | ROS2 드라이버 개발 | 매뉴얼 또는 엔지니어 |
| 제어 API / SDK | 명령 전송 방식 | 벤더 제공 |
| I/O 사양 (포트 수, 타입) | 그리퍼 제어 | 매뉴얼 사양표 |
| 안전 기능 | 안전 설정 | 매뉴얼 |

## 벤더 엔지니어에게 요청할 데이터 체크리스트

아래 내용을 엔지니어에게 전달하여 데이터를 수집한다:

```
===== CGXI R12 시뮬레이션용 데이터 요청 =====

안녕하세요, CGXI G-Series R12 로봇을 ROS2 기반으로
시뮬레이션하려고 합니다. 아래 데이터를 제공해주실 수 있나요?

[필수]
□ 각 조인트(J1~J6) 동작 범위 (degree)
□ 각 조인트 최대 속도 (degree/s)
□ 각 조인트 최대 토크 또는 정격 토크 (Nm)
□ 링크 치수 도면 (각 축 간 거리, mm)
□ DH 파라미터 (있는 경우)
□ 로봇 좌표계 원점 위치 및 방향 설명
□ TCP 기본 위치 (플랜지 면 기준 오프셋)

[권장 — 더 정확한 시뮬레이션을 위해]
□ 각 링크의 질량 (kg)
□ 각 링크의 무게중심 좌표 (mm)
□ 각 링크의 관성 모멘트 (kg·m²)

[실제 로봇 연동 예정 시]
□ 통신 프로토콜 (Ethernet/Modbus/EtherCAT 등)
□ 외부 제어 API 또는 SDK 문서
□ ROS/ROS2 드라이버 제공 여부

□ 3D 파일은 이미 보유 중 (STEP/IGES/STL)

감사합니다.
================================================
```

## Step 3: 3D 메쉬 변환

벤더에서 받은 3D 파일(STEP, IGES 등)을 Gazebo에서 사용 가능한 형식으로 변환.

### 변환 도구
- **FreeCAD** (무료, 오픈소스): STEP → STL/DAE 변환
- **MeshLab** (무료): 메쉬 단순화, 수정
- **Blender** (무료): 복잡한 메쉬 작업

### 변환 절차

```bash
# FreeCAD를 사용한 변환 (WSL2에서)
sudo apt install -y freecad

# Python 스크립트로 배치 변환
freecadcmd convert_mesh.py
```

### 핵심 규칙
- **Visual 메쉬**: 원본 품질 유지 (DAE 형식 권장, 색상 포함)
- **Collision 메쉬**: 단순화된 형태 (STL, 폴리곤 수 줄이기)
  - 시뮬레이션 속도를 위해 collision은 반드시 단순화
- **단위**: 미터(m) 기준으로 통일
- **원점**: 각 링크의 조인트 축 중심에 맞추기

### 3D 파일을 링크별로 분리

전체 로봇이 하나의 파일인 경우 링크별로 분리해야 한다:
```
meshes/
├── visual/
│   ├── base_link.dae
│   ├── link1.dae
│   ├── link2.dae
│   ├── link3.dae
│   ├── link4.dae
│   ├── link5.dae
│   └── link6.dae
└── collision/
    ├── base_link.stl
    ├── link1.stl
    ├── link2.stl
    ├── link3.stl
    ├── link4.stl
    ├── link5.stl
    └── link6.stl
```

## Step 4: URDF 작성

매뉴얼의 치수 정보 + 메쉬 파일을 조합하여 URDF를 작성한다.

### URDF 기본 구조 (6축 로봇)

```xml
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro" name="cgxi_r12">

  <!-- ========== Base Link ========== -->
  <link name="base_link">
    <visual>
      <geometry>
        <mesh filename="package://cgxi_r12_description/meshes/visual/base_link.dae"/>
      </geometry>
    </visual>
    <collision>
      <geometry>
        <mesh filename="package://cgxi_r12_description/meshes/collision/base_link.stl"/>
      </geometry>
    </collision>
    <inertial>
      <mass value="5.0"/>  <!-- 엔지니어 확인 필요 -->
      <origin xyz="0 0 0.05" rpy="0 0 0"/>
      <inertia ixx="0.01" ixy="0" ixz="0" iyy="0.01" iyz="0" izz="0.01"/>
    </inertial>
  </link>

  <!-- ========== Joint 1 (Base → Link1) ========== -->
  <joint name="joint_1" type="revolute">
    <parent link="base_link"/>
    <child link="link_1"/>
    <origin xyz="0 0 0.XXX" rpy="0 0 0"/>  <!-- 매뉴얼 치수 -->
    <axis xyz="0 0 1"/>  <!-- Z축 회전 -->
    <limit lower="-6.2832" upper="6.2832"
           velocity="2.094" effort="100"/>  <!-- 매뉴얼 사양 -->
  </joint>

  <link name="link_1">
    <visual>
      <geometry>
        <mesh filename="package://cgxi_r12_description/meshes/visual/link1.dae"/>
      </geometry>
    </visual>
    <collision>
      <geometry>
        <mesh filename="package://cgxi_r12_description/meshes/collision/link1.stl"/>
      </geometry>
    </collision>
    <inertial>
      <mass value="4.0"/>
      <origin xyz="0 0 0.1" rpy="0 0 0"/>
      <inertia ixx="0.01" ixy="0" ixz="0" iyy="0.01" iyz="0" izz="0.01"/>
    </inertial>
  </link>

  <!-- Joint 2 ~ Joint 6 동일 패턴으로 반복 -->
  <!-- 매뉴얼의 DH 파라미터 또는 치수 도면을 기반으로 작성 -->

</robot>
```

### 조인트 축 방향 규칙 (일반적인 6축 코봇)
| 조인트 | 회전축 | 설명 |
|--------|--------|------|
| J1 | Z축 (0,0,1) | 베이스 회전 |
| J2 | Y축 (0,1,0) | 어깨 전후 |
| J3 | Y축 (0,1,0) | 팔꿈치 전후 |
| J4 | Z축 (0,0,1) | 손목 회전 |
| J5 | Y축 (0,1,0) | 손목 굽힘 |
| J6 | Z축 (0,0,1) | 플랜지 회전 |

※ 실제 축 방향은 매뉴얼 좌표계 설명으로 확인 필수

## Step 5~7: Gazebo → MoveIt2 연동

URDF 작성 후 테스트 순서:

```bash
# 1. URDF 문법 검증
check_urdf cgxi_r12.urdf

# 2. RViz에서 모델 표시 테스트
ros2 launch cgxi_r12_description display.launch.py

# 3. Gazebo에서 스폰 테스트
ros2 launch cgxi_r12_gazebo gazebo.launch.py

# 4. MoveIt2 Setup Assistant로 설정 생성
ros2 launch moveit_setup_assistant setup_assistant.launch.py
```

MoveIt2 Setup Assistant에서 설정할 항목:
- 자기충돌 매트릭스 (Self-Collision Matrix)
- 플래닝 그룹 정의 (arm, gripper)
- 엔드이펙터 정의
- 기본 자세 (Home, Ready 등)
- ROS2 컨트롤러 설정

## Step 8: 검증 체크리스트

| 항목 | 확인 |
|------|------|
| URDF 문법 오류 없음 | check_urdf 통과 |
| RViz에서 모델 정상 표시 | 링크/조인트 구조 확인 |
| 조인트 슬라이더로 각 축 동작 | joint_state_publisher_gui |
| Gazebo에서 정상 스폰 | 바닥에 안정적으로 서 있음 |
| 조인트 범위가 매뉴얼과 일치 | 각 축 최대/최소 각도 확인 |
| 도달거리가 사양과 일치 | TCP를 최대로 뻗었을 때 1,300mm |
| MoveIt2 모션 플래닝 성공 | 임의 목표점에 경로 생성 확인 |
| 자기충돌 감지 정상 | 비정상 자세로 이동 시 차단 |

검증 완료 후 robots/{robot-name}/README.md에 "온보딩 완료" 표시.
