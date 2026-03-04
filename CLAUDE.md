# Robot Simulation Platform — AI 어시스턴트

## 프로젝트 목적
보유 중인 협업로봇들의 시뮬레이션 기반 작업 개발을 AI가 지원한다.
로봇 온보딩, 환경 구축, 시뮬레이션 구성, 결과 분석, 개선안 도출까지의
전체 워크플로우를 로봇 기종에 관계없이 통합 관리한다.

## 보유 로봇

### 1. Doosan M1013
- 자유도: 6축 | 가반하중: 10 kg | 도달거리: 1,300 mm
- 반복정밀도: ±0.1 mm | TCP 속도: 1 m/s
- 통신: Ethernet (IP: 192.168.137.100, Port: 12345)
- ROS2 지원: 공식 패키지 (doosan-robot2)
- 상세 사양: robots/doosan-m1013/README.md

### 2. CGXI G-Series R12
- 자유도: 6축 | 가반하중: 12 kg | 도달거리: 1,300 mm
- 반복정밀도: ±0.03 mm | TCP 속도: 3 m/s
- 통신: (확인 필요 — 벤더 엔지니어에게 문의 가능)
- ROS2 지원: 없음 → URDF 직접 제작 필요 (3D 파일 보유)
- 상세 사양: robots/cgxi-r12/README.md
- 벤더 자료: robots/cgxi-r12/vendor-docs/

## 시뮬레이션 환경
- Host OS: Windows 10 (Build 19044+)
- WSL2: Ubuntu 22.04 (Jammy)
- ROS2: Humble Hawksbill
- Gazebo: Fortress (via ros-humble-gazebo-ros-pkgs)
- MoveIt2: Humble 호환 버전
- Docker: 두산 DRCF 에뮬레이터용

## 스킬 (슬래시 커맨드)
스킬 파일 위치: `.claude/skills/{skill-name}/SKILL.md`

| 커맨드 | 용도 |
|--------|------|
| `/robot-onboarding` | 새 로봇 추가 / URDF 제작 |
| `/environment-setup` | 환경 구축/설치/에러 관련 |
| `/simulation-builder` | Gazebo 월드 구성/장치 배치 |
| `/task-skill-library` | 작업 프로그래밍 (Pick&Place 등) |
| `/result-analyzer` | 시뮬레이션 결과 분석/보고서 |
| `/optimizer` | 성능 개선/최적화 |
| `/daily-log` | 일지/작업 정리/마무리 |
| `/equipment-registry` | 장비 등록/조회/수정 |
| `/simulation-launch` | 시뮬레이션 실행 (Gazebo/MoveIt2) |
| `/moveit2-control` | MoveIt2 로봇 제어/모션 플래닝 |
| `/task-run` | 저장된 태스크 실행/조회 |

## 로봇별 참조 규칙
- 로봇 기종별 상세 사양 → robots/{robot-name}/README.md
- 로봇 기종별 URDF → robots/{robot-name}/urdf/
- 로봇 기종별 설정 → robots/{robot-name}/config/
- 질문에 로봇 기종이 명시되지 않으면 어떤 로봇인지 확인한다

## 지식 베이스
- knowledge-base/glossary.md: 용어 사전 & 기술 가이드 인덱스 (진입점)
- knowledge-base/gazebo-guide.md: Gazebo 시뮬레이터 상세 가이드
- knowledge-base/moveit2-guide.md: MoveIt2 모션 플래닝 상세 가이드
- knowledge-base/ros2-cheatsheet.md: 공통 ROS2 명령어
- knowledge-base/installation-guide.md: 환경 구축 가이드 (13단계)
- knowledge-base/lessons-learned.md: 프로젝트 노하우 축적
- knowledge-base/external-resources.md: 외부 참고 링크
- 로봇별 사양은 robots/{robot-name}/README.md 참조

## 장비 참조 규칙
- 장비 프로필: equipment/{equipment-type}.yaml (빈 템플릿)
- 등록된 장비: equipment/{equipment-type}_{name}.yaml (실제 데이터)
- 장비 유형: cnc-lathe, parallel-gripper, fixture, workpiece
- 새 장비 등록 시 해당 유형의 템플릿을 복사하여 작성
- 시뮬레이션 월드 구성(Skill 02) 시 equipment/ 데이터를 참조

## 작업 결과 저장 규칙
- 새 시뮬레이션: workspace/projects/{robot}_{YYYY-MM-DD}_{task}/
- 분석 보고서: 해당 프로젝트의 analysis/ 폴더
- 개선 이력: 해당 프로젝트의 improvements/ 폴더

## WSL2 자동 실행 규칙

### Claude가 직접 WSL2 명령을 실행하는 방법
```
wsl -d Ubuntu-22.04 -- bash -lc "명령어"
```
- `bash -l`: 로그인 셸로 실행하여 .bashrc 환경변수 로드
- 장시간 명령(apt install, colcon build)은 timeout 600000ms로 설정
- sudo 필요 명령은 NOPASSWD 설정이 전제 (미설정 시 사용자에게 설정 안내)

### 자동 설치 워크플로우
사용자가 "환경 구축", "시뮬레이션 환경 설정" 등을 요청하면:
1. WSL2 접근 가능 여부 확인: `wsl -d Ubuntu-22.04 -- bash -lc "echo OK"`
2. sudo NOPASSWD 확인: `wsl -d Ubuntu-22.04 -- bash -lc "sudo -n true"`
3. 미설정 시 → 사용자에게 NOPASSWD 설정 명령 안내 (1회 비밀번호 입력)
4. 설정 완료 후 → `/environment-setup` 스킬의 자동 실행 절차에 따라 직접 실행
5. 각 Step 완료 시 결과를 사용자에게 보고
6. 전체 완료 후 → Gazebo 시뮬레이션 실행하여 검증

### 백업: 원클릭 스크립트
`scripts/install-all.sh`를 사용하면 WSL2 내에서 전체 설치를 한 번에 실행 가능:
```bash
bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/install-all.sh
```

## 응답 스타일
- 명령어는 복사-붙여넣기 가능한 형태로 제공 (한 줄, 백슬래시 줄바꿈 금지)
- 코드 주석은 한국어
- 시뮬레이션 vs 실제 로봇 차이점은 항상 명시
- 로봇 기종별 차이점이 있으면 비교표로 제시
- WSL2 터미널 명령은 가능한 한 Claude가 직접 실행 (사용자 부담 최소화)
