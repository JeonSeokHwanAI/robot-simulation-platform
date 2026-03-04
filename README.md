# Robot Simulation Platform

협업로봇(Cobot) 시뮬레이션 기반 작업 개발 플랫폼.
AI 어시스턴트(Claude Code)가 로봇 온보딩부터 시뮬레이션 구성, 결과 분석, 최적화까지 전체 워크플로우를 지원합니다.

## 프로젝트 목적

제조 현장에서 사용하는 협업로봇의 작업 프로그램을 **실제 로봇 없이** 시뮬레이션 환경에서 개발·검증하는 것이 목표입니다.

- 로봇 기종에 관계없이 **통합된 워크플로우**로 작업 개발
- 시뮬레이션에서 검증된 작업을 실제 로봇에 배포
- AI 어시스턴트가 환경 구축, 코드 생성, 분석까지 자동화

## 보유 로봇

| 항목 | Doosan M1013 | CGXI G-Series R12 |
|------|-------------|-------------------|
| 자유도 | 6축 | 6축 |
| 가반하중 | 10 kg | 12 kg |
| 도달거리 | 1,300 mm | 1,300 mm |
| 반복정밀도 | ±0.1 mm | ±0.03 mm |
| TCP 속도 | 1 m/s | 3 m/s |
| ROS2 지원 | 공식 패키지 (doosan-robot2) | 없음 (URDF 직접 제작) |

## 시뮬레이션 환경

| 구성요소 | 버전 |
|----------|------|
| Host OS | Windows 10 |
| WSL2 | Ubuntu 22.04 (Jammy) |
| ROS2 | Humble Hawksbill |
| Gazebo | Fortress |
| MoveIt2 | Humble 호환 |
| Docker | DRCF 에뮬레이터용 |

## 프로젝트 구조

```
robot-simulation-platform/
├── robots/                # 로봇별 사양, URDF, 설정
│   ├── doosan-m1013/
│   └── cgxi-r12/
├── equipment/             # 주변 장비 프로필 (CNC, 그리퍼, 지그, 공작물)
├── knowledge-base/        # 기술 가이드, 용어 사전, 트러블슈팅
├── workspace/             # 시뮬레이션 프로젝트, 일지
├── scripts/               # 자동화 스크립트
├── .claude/skills/        # AI 어시스턴트 스킬 (11종)
└── evals/                 # 스킬 테스트 케이스
```

## 워크플로우

```
로봇 온보딩 → 환경 구축 → 장비 등록 → 시뮬레이션 구성 → 작업 프로그래밍
                                                              ↓
                                          최적화 ← 결과 분석 ← 시뮬레이션 실행
                                            ↓
                                        재시뮬레이션 (반복)
```

## AI 스킬 (슬래시 커맨드)

Claude Code에서 슬래시 커맨드로 각 단계를 실행할 수 있습니다.

| 커맨드 | 용도 |
|--------|------|
| `/robot-onboarding` | 새 로봇 추가, URDF 제작 |
| `/environment-setup` | WSL2 + ROS2 + Gazebo 환경 구축 |
| `/equipment-registry` | 주변 장비 등록·조회·수정 |
| `/simulation-builder` | Gazebo 월드 구성, 장치 배치 |
| `/simulation-launch` | 시뮬레이션 실행 (Gazebo/MoveIt2) |
| `/task-skill-library` | 작업 프로그래밍 (Pick & Place 등) |
| `/task-run` | 저장된 태스크 실행·조회 |
| `/moveit2-control` | MoveIt2 로봇 제어, 모션 플래닝 |
| `/result-analyzer` | 시뮬레이션 결과 분석, 보고서 |
| `/optimizer` | 성능 개선, 경로 최적화 |
| `/daily-log` | 프로젝트 일지 작성 |

## 현재 진행 상황

- [x] Doosan M1013 환경 구축 완료 (WSL2 + ROS2 + Gazebo + MoveIt2)
- [x] Doosan M1013 Gazebo 시뮬레이션 실행 확인
- [x] Doosan M1013 MoveIt2 모션 플래닝 테스트 완료
- [x] CGXI R12 벤더 매뉴얼 분석 완료
- [x] 장비 등록 체계 구축 (CNC, 그리퍼, 공작물)
- [ ] CGXI R12 벤더 데이터 요청서 발송 (DH 파라미터, 동역학)
- [ ] CGXI R12 URDF 제작
- [ ] 첫 Pick & Place 시뮬레이션

## 빠른 시작

### 환경 구축 (원클릭)

WSL2 Ubuntu 22.04 터미널에서:

```bash
bash /mnt/e/WorkSpace/robot-simulation-platform/scripts/install-all.sh
```

또는 Claude Code에서 `/environment-setup` 스킬을 사용하면 단계별로 자동 설치됩니다.

## 라이선스

Private project — All rights reserved.
