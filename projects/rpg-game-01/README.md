---
title: RPG GAME 01 — 프로젝트 정본
date: 2026-07-17
status: 핵심 컨셉 승격 완료 · 게임명 미정
decision_owner: director
---

# RPG GAME 01 — 게임명 미정

> 매일 걸어서 모은 **예측 여유**를 들고, 불완전한 AI 안내자와 함께 규칙이 서로 다른 창작 세계에 강제로 로드되어 적의 움직임과 서사를 읽고 살아남는 멀티버스 액션 RPG.

이 디렉터리는 2026-07-17 이사님이 승격한 **RPG GAME 01의 제품 정본**이다. 이후 이 게임에 관한 세계관·서사·캐릭터·전투·걷기·매트릭스 연동 결정은 이 하위에 기록한다. 과거 `ideation/` 문서는 삭제하거나 이동하지 않고 근거 자료로 보존하며, 현행 여부는 [`legacy-source-map.md`](legacy-source-map.md)에서 판정한다.

## 현재 확정된 중심축

- 매트릭스 공장은 게임 밖의 생성 도구이면서 게임 안의 **세계 로더**다.
- 주인공은 규칙과 장르가 다른 세계로 강제 이동하며 임시 역할·관계를 부여받는다.
- 플레이어는 인물·사건·문화·전투 문법을 읽어 현재 어떤 이야기 속에 들어왔는지 추리한다.
- 전투는 적의 눈·발·어깨·무기 움직임을 관찰하고, 불완전한 AI의 확률 예측을 참고해 패링·회피를 결정한다.
- 걷기는 공격력을 사는 자원이 아니라 **실수할 수 있는 시간과 추가 분석 기회**를 늘리는 보너스 자원이다.
- 서로 다른 세계에서 얻은 기억·능력·관계 조각과 같은 인물의 다른 버전이 장기 축에 누적된다.
- 각 세계는 잃어버린 원본 현실과 연결된 단서를 남긴다. 다만 진짜 음모와 AI 안내자의 정체는 아직 확정하지 않는다.

## 결정 상태

| 구분 | 상태 | 정본 |
|---|---|---|
| 제품 핵심 | 승인 | [`decisions/2026-07-17-core-concept.md`](decisions/2026-07-17-core-concept.md) |
| 코어 플레이 루프 | 승인된 방향·세부 검증 전 | [`design/core-loop.md`](design/core-loop.md) |
| 관찰·예측·패링 | 승인된 방향·수치 검증 전 | [`design/combat-observation-system.md`](design/combat-observation-system.md) |
| 걷기 자원 | 승인된 방향·명칭/밸런스 미정 | [`design/walk-prediction-buffer.md`](design/walk-prediction-buffer.md) |
| 멀티버스 연속성 | 승인된 방향·구체 인스턴스 미정 | [`design/multiverse-continuity.md`](design/multiverse-continuity.md) |
| 매트릭스 연동 | 경계 확정·제품 어댑터 미구현 | [`design/matrix-factory-boundary.md`](design/matrix-factory-boundary.md) |
| 핵심 음모·게임명 | **결정 대기** | [`decisions/OPEN-conspiracy-and-title.md`](decisions/OPEN-conspiracy-and-title.md) |

RPG 팀장 세션 복구와 기억 규칙은 [`TEAM-BOOT.md`](TEAM-BOOT.md)를 따른다.

## 이름 규칙

- 정식 게임명은 아직 없다.
- 내부 프로젝트명은 항상 **`RPG GAME 01` / `rpg-game-01`**을 쓴다.
- 핵심 음모의 진실과 공개 방식이 승인되기 전에는 후보 이름도 정식명처럼 사용하지 않는다.

## 작업 경계

- 이 문서 승격은 **설계 정본화**이며 게임 구현·AWS 배포·매트릭스 런 생성을 허가하지 않는다.
- 새 세계·주인공·AI 안내자·캐릭터 인스턴스는 이사님이 먼저 체감하고 승인한 뒤 채택한다.
- 폐기된 `manufacturing-coverup-B01`은 이름이 비슷한 새 음모 후보로도 자동 부활시키지 않는다.
- 바이너리 원본/에셋을 이 경로에 복사하지 않는다. 제품 정본은 구조화된 설계와 검증된 참조를 우선한다.

## 다음 대화의 첫 안건

[`decisions/OPEN-conspiracy-and-title.md`](decisions/OPEN-conspiracy-and-title.md)의 질문을 바탕으로 **이 게임의 진짜 음모**를 함께 만든다. 그 결정이 게임명 탐색의 입력이다.
