---
title: RPG GAME 01 팀장 세션 복구 규칙
date: 2026-07-17
status: required
project_id: rpg-game-01
target_actor: aws-rpg
---

# RPG GAME 01 팀장 세션 복구 규칙

RPG 팀장은 새 세션·초기화·모델 변경 뒤 대화 기억을 정본으로 사용하지 않는다. 작업 전 공유된 Git 커밋에서 다음 순서로 다시 읽는다.

1. [`project.json`](project.json)
2. [`README.md`](README.md)
3. [`decisions/2026-07-17-core-concept.md`](decisions/2026-07-17-core-concept.md)
4. [`decisions/OPEN-conspiracy-and-title.md`](decisions/OPEN-conspiracy-and-title.md)
5. [`legacy-source-map.md`](legacy-source-map.md)
6. 현재 받은 Agent Mail의 범위·금지·완료조건

## 복구 후 반드시 알고 있어야 할 것

- 프로젝트 ID는 `rpg-game-01`, 표시명은 `RPG GAME 01`이다.
- 게임명은 핵심 음모 승인 전까지 미정이다.
- 중심축은 강제 세계 로드, 서사/규칙 추리, 관찰형 패링, 불완전한 AI, 걷기 예측 버퍼, 멀티버스 연속성, 매트릭스 세계 로더다.
- 구체 주인공·AI·세계·캐릭터 인스턴스는 이사님 체감·승인 없이 전제하지 않는다.
- `manufacturing-coverup-B01`은 폐기 상태이며 자동 부활시키지 않는다.
- 아이디어 승인과 구현 허가는 다르다. 별도 실행 지시 없이는 코드·배포·자산 승격을 하지 않는다.

## 첫 ACK에 포함할 것

- `actor_id=aws-rpg` 확인.
- 읽은 RPG Git의 전체 40자 커밋.
- 위 여섯 핵심 기억의 이해 여부.
- 현재 지시가 기억/보고인지, 설계인지, 구현인지 구분.
- 충돌·누락이 있으면 실행하지 않고 정확한 항목을 보고.

Telegram의 과거 대화나 봇 이름만으로 기억을 복원했다고 주장하지 않는다.
