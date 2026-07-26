---
title: 파랜드풍 챕터 세로 조각 구현 경계
date: 2026-07-26
status: implemented-awaiting-director-feel-review
decision_owner: director
project_id: rpg-game-01
---

# 파랜드풍 챕터 세로 조각 구현 경계

## 구현한 흐름

`하늘에 남은 문` 검증 챕터에 아래 흐름을 연결했다.

1. 아리아·카엘·세나의 출격 대화
2. 등각 전장에서의 이동·공격·패링
3. 흑창병 약화 시 세나와 별의 교단 관계 공개
4. 승패 결과 대화와 다음 세계 단서

## 코드 경계

- `TacticsCore`: 이동, 공격, 턴, 반응 판정
- `BattleScenario`: 등장인물, 대화, 목표, 전투 이벤트 데이터
- `BattleDirector`: 브리핑→전투→이벤트→결과 상태 전환
- `TacticsBattle`: 입력, 초상화, SD 유닛, 이동·피해 연출

`BattleScenario.matrix_contract`는 이후 Matrix 어댑터가 채울 최소 슬롯만 선언한다.
Matrix가 Godot 노드를 직접 조작하지 않고 검증된 시나리오 데이터를 공급하는 경계다.

## 비주얼 자산

`demo/assets/tactics/chapter01/`의 초상화와 SD 유닛은 이 체감 검증을 위해 새로 생성한
오리지널 프로토타입 자산이다. 정식 캐릭터 디자인이나 제품 본편 자산으로 승격하지 않는다.

## 승인되지 않은 것

- 아리아·카엘·세나와 별의 교단은 정식 캐릭터·세계관으로 승인되지 않았다.
- 검증 챕터의 대사는 핵심 음모의 정본이 아니다.
- 이 구현은 `main` 통합이나 production 승인을 뜻하지 않는다.
