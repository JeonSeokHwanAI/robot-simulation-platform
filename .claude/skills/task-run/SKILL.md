---
name: task-run
description: "저장된 태스크 실행. 태스크 목록 조회, 태스크 실행, 태스크 불러오기"
---

# 태스크 실행

## 개요

저장된 로봇 태스크를 조회하고 실행하는 스킬.
시뮬레이션이 가동 중인 상태에서 태스크를 선택하여 실행한다.

---

## 실행 절차

### Step 1: 시뮬레이션 가동 확인

태스크 실행 전, Gazebo + MoveIt2 시뮬레이션이 가동 중인지 확인한다:

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && ros2 action info /sim/move_action 2>/dev/null | grep -q 'Action servers: 1' && echo 'SIM_RUNNING' || echo 'SIM_NOT_RUNNING'"
```

- `SIM_RUNNING` → Step 2로 진행
- `SIM_NOT_RUNNING` → 사용자에게 `/simulation-launch`로 시뮬레이션 먼저 시작하라고 안내

### Step 2: 태스크 목록 표시

**답변창에 직접** 태스크 목록을 마크다운 테이블로 출력한다. AskUserQuestion은 사용하지 않는다.

1. `robots/*/tasks/*.py` Glob으로 전체 태스크 파일 검색
2. 각 태스크 파일을 Read하여 아래 정보를 추출:
   - `TASK_PURPOSE`: 용도
   - `TASK_DESC`: 간단 설명
   - `VELOCITY_SCALE`: 속도
   - `WAYPOINTS` 항목 수: 스텝 수
3. `robots/{robot-name}/tasks/.stats.json` Read하여 소요시간 정보 로드
4. 아래 형식의 **테이블 하나만** 출력한다:

```
## Doosan M1013 — 등록 태스크

| # | 태스크명 | 용도 | 설명 | 속도 | 스텝 | 소요시간 |
|---|---------|------|------|------|------|---------|
| 1 | pick_and_load | 데모 시연용 | Pick & Load 표준 | 30% | 7 | 51초 |
| 2 | pick_and_load_fast | 데모 시연용 | Pick & Load 고속 | 50% | 7 | 36초 |

실행할 태스크 번호 또는 이름을 입력하세요.
```

- 소요시간은 `.stats.json`에 기록이 있으면 표시, 없으면 `-` 표시
- 테이블 아래에 상세 정보를 별도로 나열하지 않는다

### Step 3: 사용자 입력 대기

**AskUserQuestion을 사용하지 않는다.** 사용자가 채팅창에 직접 번호(예: `1`) 또는 이름(예: `pick_and_load_fast`)을 입력하면 매칭하여 실행한다.

### Step 4: 태스크 실행 및 시간 기록

사용자가 입력한 번호/이름에 해당하는 태스크를 실행한다:

```bash
wsl -d Ubuntu-22.04 -- bash -lc "source ~/ros2_ws/install/setup.bash && python3 /mnt/e/WorkSpace/robot-simulation-platform/robots/{robot-name}/tasks/{task-name}.py"
```

- timeout: 300000 (5분)
- 실행 결과 로그를 사용자에게 표시

**실행 완료 후**, 로그에서 총 소요시간을 계산하여 `.stats.json`에 기록한다:
- 로그의 첫 번째 `Task Start` 타임스탬프 ~ 마지막 `Task Complete` 타임스탬프 차이를 초 단위로 계산
- `robots/{robot-name}/tasks/.stats.json`을 Read → 해당 태스크 항목 업데이트 → Write

`.stats.json` 형식:
```json
{
  "pick_and_load": {"duration_sec": 51, "last_run": "2026-03-04"},
  "pick_and_load_fast": {"duration_sec": 36, "last_run": "2026-03-04"}
}
```

### Step 5: 완료 후

태스크 완료 후 아래 문구를 출력한다:

> 태스크 완료 (XX초). 다시 실행하려면 번호를, 목록을 보려면 `/task-run`을 입력하세요.

---

## 태스크 파일 규칙

태스크 Python 파일은 아래 규칙을 따른다:

- 위치: `robots/{robot-name}/tasks/{task-name}.py`
- `TASK_PURPOSE`: 용도 (목록 표시용, 예: '데모 시연용', '생산 테스트용')
- `TASK_DESC`: 간단 설명 (목록 표시용, 예: 'Pick & Load 표준')
- `VELOCITY_SCALE`, `ACCEL_SCALE`, `STEP_PAUSE`: 속도/가속/대기 설정
- `WAYPOINTS` 리스트: 웨이포인트 정의
- `TaskRunner` 클래스: MoveGroup 액션 순차 실행

## 소요시간 기록

- 파일: `robots/{robot-name}/tasks/.stats.json`
- 태스크 실행 완료 시 자동 업데이트
- 첫 실행 전에는 데이터 없음 → 테이블에 `-` 표시

---

## 트리거 키워드

'태스크 실행', '태스크 목록', '태스크 불러오기', 'task run', '저장된 태스크', '작업 실행'
