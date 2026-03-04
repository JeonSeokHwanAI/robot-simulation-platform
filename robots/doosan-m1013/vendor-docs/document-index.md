# Doosan M1013 벤더 자료 목록

Doosan Robotics 공식 기술 문서 및 ROS2 패키지 내 데이터.

## 다운로드된 문서

| # | 파일명 | 내용 | 출처 |
|---|--------|------|------|
| 1 | Doosan_Robotics_User_Manual_V2.7.1_EN.pdf | 전체 사용자 매뉴얼 (242p, 영문) | 두산 공식 |

## 온라인 문서 (다운로드 불필요)

| # | 링크 | 내용 |
|---|------|------|
| 1 | [두산 공식 온라인 매뉴얼](https://manual.doosanrobotics.com/en/user/2.10/1.-M-H-Series/m1013) | M1013 웹 매뉴얼 (최신 버전) |
| 2 | [ManualsLib](https://www.manualslib.com/products/Doosan-M1013-12268219.html) | User/Reference/Installation Manual 등 8종 |
| 3 | [두산 공식 제품 페이지](https://www.doosanrobotics.com/en/product-solutions/product/m-series/m1013/) | 제품 사양, 브로셔 |

## ROS2 패키지 내 기술 데이터 (doosan-robot2)

공식 ROS2 패키지에 URDF, MoveIt2 설정, 메쉬 파일이 포함되어 있어
벤더 문서에서 별도 추출이 불필요하다.

| 데이터 | 위치 (WSL2) |
|--------|-------------|
| URDF/Xacro | `~/ros2_ws/src/doosan-robot2/dsr_description2/xacro/` |
| 3D 메쉬 | `~/ros2_ws/src/doosan-robot2/dsr_description2/meshes/m1013_white/` |
| MoveIt2 설정 | `~/ros2_ws/src/doosan-robot2/dsr_moveit2/dsr_moveit_config_m1013/` |
| ros2_control | `~/ros2_ws/src/doosan-robot2/dsr_description2/ros2_control/` |
| 컨트롤러 설정 | `~/ros2_ws/src/doosan-robot2/dsr_controller2/config/` |

### URDF에서 추출된 조인트/링크 사양

#### 조인트 사양

| 조인트 | 동작 범위 | 최대 속도 | 최대 토크 |
|--------|-----------|-----------|-----------|
| J1 | ±360° (±6.2832 rad) | 120°/s (2.0944 rad/s) | 346 Nm |
| J2 | ±360° (±6.2832 rad) | 120°/s (2.0944 rad/s) | 346 Nm |
| J3 | ±160° (±2.7925 rad) | 180°/s (3.1416 rad/s) | 163 Nm |
| J4 | ±360° (±6.2832 rad) | 225°/s (3.927 rad/s) | 50 Nm |
| J5 | ±360° (±6.2832 rad) | 225°/s (3.927 rad/s) | 50 Nm |
| J6 | ±360° (±6.2832 rad) | 225°/s (3.927 rad/s) | 50 Nm |

#### 링크 사양

| 링크 | 질량 (kg) | 무게중심 (x, y, z) m |
|------|----------|---------------------|
| Base | 4.12 | (-0.00003, -0.00482, 0.04848) |
| Link1 | 7.80 | (0.00012, 0.04280, -0.00638) |
| Link2 | 10.83 | (0.25973, -0.00005, 0.15782) |
| Link3 | 3.68 | (-0.00002, -0.00670, 0.04461) |
| Link4 | 3.82 | (0.00007, 0.09188, -0.18252) |
| Link5 | 2.82 | (-0.00027, 0.00365, 0.03209) |
| Link6 | 1.16 | (-0.00029, 0.00001, -0.05390) |
| **합계** | **34.23** | — |

#### 링크 간 오프셋 (조인트 origin)

| 조인트 | 부모→자식 오프셋 (m) | 비고 |
|--------|---------------------|------|
| J1 | (0, 0, 0.1525) | 베이스 높이 152.5mm |
| J2 | (0, 0.0345, 0) + rpy(-90°, -90°) | y축 오프셋 34.5mm |
| J3 | (0.62, 0, 0) | 상완 길이 620mm |
| J4 | (0, -0.559, 0) + rpy(90°, 0°) | 전완 길이 559mm |
| J5 | (0, 0, 0) + rpy(-90°, 0°) | 손목 회전축 |
| J6 | (0, -0.121, 0) + rpy(90°, 0°) | 손목 길이 121mm |

## CGXI R12과의 비교

두산 M1013은 공식 패키지에 **정확한** 동역학 데이터가 포함되어 있어
벤더 문서 분석이 거의 불필요한 반면,
CGXI R12은 ROS2 패키지가 없어 벤더 문서에서 직접 데이터를 추출해야 한다.
