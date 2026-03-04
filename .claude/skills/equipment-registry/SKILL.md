---
name: equipment-registry
description: "시뮬레이션에 사용할 주변 장비(CNC, 그리퍼, 지그, 공작물)를 등록·조회·수정하는 스킬. 장비 프로필은 YAML 파일로 관리되며, 시뮬레이션 월드 구성(Skill 02)과 작업 프로그래밍(Skill 03)에서 참조된다. '장비 등록', '그리퍼 추가', 'CNC 등록', '공작물 정의', '지그 설정', '장비 목록', '장비 수정' 등의 요청에 트리거."
---

# 장비 등록 가이드

## 개요

로봇 시뮬레이션에 필요한 주변 장비를 구조화된 YAML 프로필로 관리한다.
등록된 장비 데이터는 Gazebo 월드 구성(Skill 02)과 작업 프로그래밍(Skill 03)에서 참조된다.

## 장비 유형

| 유형 | 템플릿 파일 | 설명 |
|------|------------|------|
| CNC 선반 | `equipment/cnc-lathe.yaml` | 공작기계 (도어, 척, 가공 사이클) |
| 평행 그리퍼 | `equipment/parallel-gripper.yaml` | 로봇 엔드이펙터 (파지력, TCP 오프셋) |
| 고정구(지그) | `equipment/fixture.yaml` | 소재/완성품 트레이, 팔레트 |
| 공작물 | `equipment/workpiece.yaml` | 가공 대상물 (치수, 물성, 파지 조건) |

## 장비 등록 절차

```
1. 장비 유형 확인 → 해당 YAML 템플릿 선택
2. 템플릿을 복사하여 equipment/ 에 새 파일 생성
   (파일명 규칙: {유형}_{이름}.yaml, 예: cnc-lathe_fanuc-alpha.yaml)
3. 필드 채우기 (필수 필드 → 권장 필드 → 선택 필드)
4. YAML 문법 검증
5. 관련 시뮬레이션 모델(SDF/URDF)이 있으면 경로 기록
```

## 장비 유형별 필수 필드

### CNC 선반 (cnc-lathe)

| 필드 | 설명 | 왜 필요한가 |
|------|------|-------------|
| `dimensions.*` | 외형 치수 | Gazebo 월드 배치 및 충돌 모델 |
| `chuck.type` | 척 방식 | 시뮬레이션 로직 (열림/닫힘 시간) |
| `access_points.*` | 로봇 접근 좌표 | MoveIt2 목표 포즈 |
| `communication.signals.*` | 제어 신호 | ROS2 토픽/서비스 매핑 |
| `cycle.typical_time_s` | 가공 시간 | 사이클 타임 시뮬레이션 |

### 평행 그리퍼 (parallel-gripper)

| 필드 | 설명 | 왜 필요한가 |
|------|------|-------------|
| `gripper.stroke_mm` | 개폐 거리 | 파지 가능한 공작물 크기 결정 |
| `gripper.grip_force_n` | 파지력 | 공작물 파지 가능 여부 판단 |
| `mounting.tcp_offset` | TCP 오프셋 | MoveIt2 엔드이펙터 위치 보정 |
| `gripper.weight_kg` | 그리퍼 무게 | 로봇 가반하중 계산 |

### 고정구 (fixture)

| 필드 | 설명 | 왜 필요한가 |
|------|------|-------------|
| `dimensions.*` | 외형 치수 | Gazebo 월드 배치 |
| `placement.*` | 배치 좌표 | 로봇 작업 범위 내 위치 결정 |
| `clamping.workpiece_shape` | 공작물 형상 | 호환성 확인 |

### 공작물 (workpiece)

| 필드 | 설명 | 왜 필요한가 |
|------|------|-------------|
| `raw_dimensions.*` | 치수 | 그리퍼 호환성 확인 |
| `physics.mass_kg` | 질량 | 로봇 가반하중 확인, Gazebo 물리 |
| `grasping.*` | 파지 조건 | 그리퍼 파라미터 결정 |

## 등록된 장비 조회

### 파일 구분 규칙

```
equipment/
├── cnc-lathe.yaml                      ← 빈 템플릿 (이름에 _ 없음)
├── parallel-gripper.yaml               ← 빈 템플릿
├── fixture.yaml                        ← 빈 템플릿
├── workpiece.yaml                      ← 빈 템플릿
├── README.md                           ← 등록 장비 요약 (자동 갱신)
├── cnc-lathe_lynx-2100lb.yaml          ← 등록된 장비 (이름에 _ 있음)
├── parallel-gripper_robotiq-2f140.yaml ← 등록된 장비
└── workpiece_s45c-round-30x50.yaml     ← 등록된 장비
```

### 조회 워크플로우

사용자가 아래와 같이 요청하면 해당 절차를 따른다:

**"장비 목록" / "등록된 장비 보여줘"**
1. `equipment/README.md`를 읽어 요약 테이블을 보여준다
2. README.md가 최신이 아니면 YAML 파일들을 스캔하여 갱신 후 보여준다

**"CNC 사양 알려줘" / "{장비명} 정보"**
1. `equipment/` 에서 해당 유형의 `_`가 포함된 YAML 파일을 찾는다
2. YAML을 읽어 핵심 사양을 표로 정리하여 보여준다

**"장비 호환성 확인" / "이 공작물 잡을 수 있어?"**
1. 공작물 YAML에서 치수, 질량, 파지 조건을 읽는다
2. 그리퍼 YAML에서 스트로크, 파지력, 페이로드를 읽는다
3. 로봇 README.md에서 가반하중을 읽는다
4. 호환성 결과를 표로 보여준다:
   - 공작물 직경 vs 그리퍼 스트로크
   - 필요 파지력 vs 그리퍼 파지력
   - 공작물+그리퍼 무게 vs 로봇 가반하중

**"장비 수정" / "{장비명} 사양 업데이트"**
1. 해당 YAML 파일을 읽어 현재 값을 보여준다
2. 수정할 필드와 새 값을 사용자에게 확인한다
3. YAML 파일을 수정하고 equipment/README.md를 갱신한다

### README.md 갱신 규칙

장비를 등록, 수정, 삭제할 때마다 `equipment/README.md`를 갱신한다.
README.md에는 등록된 장비의 요약 테이블과 호환성 매트릭스를 포함한다.

## 다른 스킬과의 연계

| 연계 스킬 | 사용 방식 |
|-----------|-----------|
| Skill 02 (simulation-builder) | 장비 치수·좌표로 Gazebo 월드 배치 |
| Skill 03 (task-skill-library) | access_points로 MoveIt2 목표 포즈 설정 |
| Skill 04 (result-analyzer) | cycle 파라미터로 성능 기준 비교 |

## 검증 체크리스트

| 항목 | 확인 |
|------|------|
| YAML 문법 오류 없음 | 파싱 테스트 통과 |
| 필수 필드 모두 채워짐 | 0 또는 빈 문자열이 아닌 실제 값 |
| 치수 단위 일관성 | m (미터) 또는 mm (밀리미터) 표기 확인 |
| 접근 좌표가 로봇 도달 범위 내 | 도달거리 1,300mm 이내 |
| 공작물 무게 < 로봇 가반하중 - 그리퍼 무게 | 안전 마진 확보 |
