# Robot Simulation Platform — 프로젝트 구조

## 개요
보유 로봇(Doosan M1013, CGXI R12)의 시뮬레이션 워크플로우를
Claude Code 스킬 시스템으로 통합 관리하는 프로젝트.

## 디렉토리 구조

```
robot-simulation-platform/
│
├── CLAUDE.md                          # Claude Code 루트 설정
├── PROJECT_STRUCTURE.md               # 이 문서
│
├── robots/                            # 로봇별 프로필 & 모델
│   ├── doosan-m1013/
│   │   ├── README.md                  # 사양서 (✅ 완료)
│   │   ├── urdf/                      # 공식 패키지(dsr_description2) 내 포함
│   │   ├── meshes/                    # 공식 패키지 내 포함
│   │   └── config/                    # 조인트 제한, 컨트롤러
│   │
│   └── cgxi-r12/
│       ├── README.md                  # 사양서 (✅ 매뉴얼 분석 완료, 추정 동역학 포함)
│       ├── urdf/                      # URDF 직접 제작 예정
│       ├── meshes/                    # 3D 파일 변환 후 저장
│       │   ├── visual/               # DAE (시각용)
│       │   └── collision/            # STL (충돌용, 단순화)
│       ├── config/                    # 조인트 제한, 컨트롤러
│       └── vendor-docs/              # 벤더 원본 매뉴얼/자료
│           ├── README.md              # 문서 목록 및 추출 현황
│           ├── 技术数据请求书_CGXI_R12_CN.md   # 벤더 데이터 요청서 (중국어)
│           ├── Technical_Data_Request_CGXI_R12_EN.md  # 벤더 데이터 요청서 (영어)
│           ├── (PDF 매뉴얼 3종)        # Cobots Manual, HW Manual, SW Manual
│           └── (PDF 도면 6종)          # DH, 베이스, 엔드이펙터, 작업공간 등
│
├── equipment/                         # 주변 장비 프로필 (YAML)
│   ├── README.md                      # 등록 장비 현황 & 호환성 매트릭스
│   ├── cnc-lathe.yaml                 # 빈 템플릿: CNC 선반
│   ├── cnc-lathe_lynx-2100lb.yaml     # Doosan LYNX 2100LB
│   ├── parallel-gripper.yaml          # 빈 템플릿: 평행 그리퍼
│   ├── parallel-gripper_robotiq-2f140.yaml  # Robotiq 2F-140 (임시)
│   ├── fixture.yaml                   # 빈 템플릿: 고정구(지그)
│   ├── workpiece.yaml                 # 빈 템플릿: 공작물
│   └── workpiece_s45c-round-30x50.yaml  # S45C 원형봉 Ø30×50
│
├── .claude/
│   └── skills/                        # Claude Code 슬래시 커맨드 스킬
│       ├── robot-onboarding/          # /robot-onboarding — 새 로봇 등록 & URDF
│       │   └── SKILL.md
│       ├── environment-setup/         # /environment-setup — WSL2+ROS2+Gazebo
│       │   ├── SKILL.md
│       │   └── references/
│       │       └── troubleshooting.md
│       ├── simulation-builder/        # /simulation-builder — Gazebo 월드 구성
│       │   └── SKILL.md
│       ├── task-skill-library/        # /task-skill-library — 작업 프로그래밍
│       │   ├── SKILL.md
│       │   └── references/
│       │       └── skill-template.md
│       ├── result-analyzer/           # /result-analyzer — 결과 분석
│       │   └── SKILL.md
│       ├── optimizer/                 # /optimizer — 최적화/개선
│       │   └── SKILL.md
│       ├── daily-log/                 # /daily-log — 일지/작업 정리
│       │   └── SKILL.md
│       ├── equipment-registry/        # /equipment-registry — 장비 등록/조회
│       │   └── SKILL.md
│       ├── simulation-launch/         # /simulation-launch — 시뮬레이션 실행
│       │   └── SKILL.md
│       └── moveit2-control/           # /moveit2-control — MoveIt2 제어
│           └── SKILL.md
│
├── knowledge-base/                    # 공통 지식
│   ├── glossary.md                    # 용어 사전 & 기술 가이드 인덱스
│   ├── gazebo-guide.md                # Gazebo 시뮬레이터 상세 가이드
│   ├── moveit2-guide.md               # MoveIt2 모션 플래닝 상세 가이드
│   ├── installation-guide.md          # 환경 구축 종합 가이드 (13단계)
│   ├── ros2-cheatsheet.md             # ROS2 공통 명령어
│   ├── external-resources.md          # 외부 참고 링크
│   └── lessons-learned.md             # 프로젝트 노하우 축적
│
├── scripts/                            # 자동화 스크립트
│   └── install-all.sh                 # 전체 환경 원클릭 설치 (WSL2 내 실행)
│
├── workspace/                         # 시뮬레이션 프로젝트
│   ├── daily-logs/                    # 프로젝트 일지 (YYYY-MM-DD.md)
│   ├── projects/                      # {robot}_{date}_{task}/
│   └── templates/
│       └── machine-tending/
│           └── project-definition-template.yaml  # 프로젝트 정의서 템플릿
│
└── evals/                             # 스킬 테스트 케이스
    └── evals.json
```

## WSL2 환경 (~/ros2_ws)

```
~/ros2_ws/                             # ROS2 워크스페이스 (WSL2 내부)
├── src/
│   └── doosan-robot2/                 # 두산 공식 ROS2 패키지 (22개)
│       ├── dsr_bringup2/              # 런치 파일 (시뮬레이션/실기)
│       ├── dsr_description2/          # URDF 로봇 모델
│       ├── dsr_gazebo2/               # Gazebo 시뮬레이션
│       ├── dsr_controller2/           # 로봇 제어기
│       ├── dsr_hardware2/             # 하드웨어 인터페이스
│       ├── dsr_moveit_config_m1013/   # M1013 MoveIt 설정
│       ├── dsr_common2/               # 공용 유틸리티
│       ├── dsr_msgs2/                 # 커스텀 메시지
│       ├── dsr_example/               # 예제 코드
│       └── ...
├── build/                             # 빌드 산출물
├── install/                           # 설치된 패키지
└── log/                               # 빌드 로그
```

## 스킬 연계 흐름

```
[Skill 00: 로봇 온보딩] ← 새 로봇 추가 시
        ↓
[Skill 01: 환경 구축] ← WSL2/ROS2 설치 시
        ↓
[Skill 07: 장비 등록] ← CNC, 그리퍼, 지그, 공작물 등록
        ↓
[Skill 02: 시뮬레이션 구성] → [Skill 03: 작업 프로그래밍]
        ↓                              ↓
    Gazebo 월드 생성              ROS2 동작 코드 생성
    (equipment/ 참조)             (equipment/ 참조)
        ↓                              ↓
        └──── 사용자가 시뮬레이션 실행 ────┘
                        ↓
              [Skill 04: 결과 분석]
                        ↓
              [Skill 05: 최적화]
                        ↓
                  수정 코드 생성 → 재시뮬레이션 (반복)
```

## 현재 상태

> 마지막 업데이트: 2026-03-04 (MoveIt2 모션 플래닝 테스트 완료, 장비 등록 체계 구축)

### 로봇 프로필

| 항목 | 상태 | 비고 |
|------|------|------|
| Doosan M1013 프로필 | ✅ 완료 | 기본 사양, ROS2 패키지 정보 |
| CGXI R12 프로필 | ✅ 매뉴얼 분석 완료 | 매뉴얼 3종 + 도면 6종 분석, 추정 동역학 포함 |
| CGXI R12 벤더 데이터 요청 | 📨 요청서 작성 완료 | 중국어/영어 요청서 (DH 파라미터, 동역학, SDK) |
| CGXI R12 J3/J6 ±165° 불일치 | ⚠️ 벤더 확인 필요 | Cobots Manual vs HW Manual 불일치 |

### 스킬 문서

| 항목 | 상태 |
|------|------|
| Skill 00 (온보딩) | ✅ 작성 완료 |
| Skill 01 (환경) | ✅ 작성 완료 + 실전 경험 반영 |
| Skill 02 (시뮬 구성) | ✅ 작성 완료 |
| Skill 03 (작업 스킬) | ✅ 작성 완료 |
| Skill 04 (결과 분석) | ✅ 작성 완료 |
| Skill 05 (최적화) | ✅ 작성 완료 |
| Skill 06 (일지) | ✅ 작성 완료 |
| Skill 07 (장비 등록) | ✅ 작성 완료 |
| Skill (simulation-launch) | ✅ 작성 완료 |
| Skill (moveit2-control) | ✅ 작성 완료 |

### 환경 구축 (Doosan M1013)

| Step | 구성요소 | 버전 | 상태 |
|------|----------|------|------|
| 1 | WSL2 + Ubuntu 22.04 | 22.04.5 LTS / Kernel 6.6.87.2 | ✅ 완료 |
| 2 | ROS2 Humble | humble | ✅ 완료 |
| 3 | Gazebo | 11.10.2 | ✅ 완료 |
| 4 | MoveIt2 | humble (30+ 패키지) | ✅ 완료 |
| 5 | ros2_control + 보조 도구 | humble (20+ 패키지) | ✅ 완료 |
| 6 | Docker | 28.2.2 | ✅ 완료 |
| 7 | rosdep + colcon | python3-rosdep2, colcon-common-extensions | ✅ 완료 |
| 8 | doosan-robot2 | GitHub main (22 패키지) | ✅ 완료 |
| 9 | DRCF 에뮬레이터 | doosanrobot/dsr_emulator:3.0.1 | ✅ 완료 |
| 10 | ros-humble-ros-gz (Ignition 브릿지) | 0.244.22 | ✅ 완료 |
| 11 | ros-humble-ign-ros2-control | 0.7.18 | ✅ 완료 |
| 12 | WSL2 렌더링 설정 (Ogre1 + SW렌더링) | LIBGL + IGN env | ✅ 완료 |
| 13 | Gazebo 시뮬레이션 첫 실행 | M1013 로봇 표시 확인 | ✅ 완료 |

> 상세 설치 가이드: `knowledge-base/installation-guide.md`
> 트러블슈팅 기록: `knowledge-base/lessons-learned.md`

## 다음 액션

### 즉시
1. ~~DRCF 에뮬레이터 설치 (Docker)~~ ✅ 완료
2. ~~Doosan M1013 Gazebo 시뮬레이션 첫 실행~~ ✅ 완료
3. CGXI R12 벤더에 데이터 요청서 발송

### 단기 (2주 이내)
4. ~~M1013 MoveIt2 모션 플래닝 테스트~~ ✅ 완료 (OMPL Plan Only + Plan&Execute)
5. M1013 RViz에서 인터랙티브 마커로 관절 조작
6. CGXI R12 벤더 응답 수신 → DH 파라미터/동역학 확정
7. CGXI R12 3D 파일 → STL/DAE 변환 → 링크별 분리
8. 보유 장비 등록 (그리퍼, CNC 등 → equipment/ YAML)

### 중기 (1개월)
7. CGXI R12 URDF 작성 → Gazebo 테스트
8. CGXI R12 MoveIt2 설정
9. 첫 Pick & Place 시뮬레이션 (양쪽 로봇 모두)
