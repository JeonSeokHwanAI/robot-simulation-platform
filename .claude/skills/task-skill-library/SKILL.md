---
name: task-skill-library
description: "로봇 작업 프로그래밍 스킬. Pick & Place, Machine Tending, 팔레타이징 등 작업별 ROS2/MoveIt2 코드를 생성한다. '피크 앤 플레이스', 'Pick and Place', '작업 프로그래밍', '머신텐딩', '팔레타이징', '모션 플래닝', '경로 계획', 'MoveIt' 등의 요청에 트리거."
---

# 작업 프로그래밍 가이드

## 개요
MoveIt2를 사용하여 로봇 작업(Pick & Place, Machine Tending 등)을
프로그래밍한다. ROS2 Python/C++ 노드로 구현.

## 지원 작업 유형

| 작업 | 설명 | 난이도 |
|------|------|--------|
| Pick & Place | 물체 집기 → 놓기 | 기본 |
| Machine Tending | CNC 로딩/언로딩 | 중급 |
| Palletizing | 팔레트에 적재 | 중급 |
| Assembly | 부품 조립 | 고급 |

## 기본 구조 (MoveIt2 Python)

```python
import rclpy
from rclpy.node import Node
from moveit2 import MoveIt2

class TaskNode(Node):
    def __init__(self):
        super().__init__('task_node')
        self.moveit2 = MoveIt2(node=self)

    def pick(self, pose):
        # 접근 → 파지 → 후퇴
        pass

    def place(self, pose):
        # 접근 → 해제 → 후퇴
        pass
```

## 작업 스킬 작성 시 규칙
1. 새 작업 스킬은 `references/skill-template.md` 양식을 참고
2. 시뮬레이션용 파라미터와 실제 로봇용 파라미터를 분리
3. 안전 관련 사항(속도 제한, 충돌 회피)은 반드시 포함

## 결과물
- `{project}/src/` 폴더에 ROS2 노드 코드 저장
- `{project}/config/` 폴더에 작업 파라미터 YAML 저장
