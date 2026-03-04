# 환경 구축 트러블슈팅 가이드

## WSL2 관련

### GPU 가속이 안 될 때
- WSL2에서 GPU 사용 시 Windows GPU 드라이버 최신 업데이트 필요
- `export LIBGL_ALWAYS_SOFTWARE=1`로 소프트웨어 렌더링 대체 가능

### 디스플레이 문제 (GUI가 안 뜰 때)
```bash
# WSLg 확인 (Windows 11 또는 Windows 10 최신)
echo $DISPLAY

# 수동 설정 (필요 시)
export DISPLAY=:0
```

## ROS2 관련

### rosdep init 에러
```bash
sudo rosdep init    # 이미 초기화되었으면 에러 발생 → 무시 가능
rosdep update
```

### 빌드 중 메모리 부족
```bash
# 병렬 빌드 제한
colcon build --parallel-workers 2
```

## Gazebo 관련

### 모델 다운로드 느림
```bash
# 오프라인 모델 캐시 설정
export GAZEBO_MODEL_PATH=~/gazebo_models
```

### Gazebo 실행 시 검은 화면
- WSL2 그래픽 드라이버 문제 가능성
- `LIBGL_ALWAYS_SOFTWARE=1 gazebo` 시도

---

<!-- 새로운 이슈 발생 시 여기에 추가 -->
