---
title: 파랜드풍 전술 체감 프로토타입 구현 경계
date: 2026-07-26
status: implemented-awaiting-director-feel-review
decision_owner: director
project_id: rpg-game-01
---

# 파랜드풍 전술 체감 프로토타입 구현 경계

## 이사님 지시와 승인

이사님은 RPG GAME 01의 전투 방향을 먼저 체감하기 위해 파랜드 택틱스풍 등각 전술
프로토타입 구현을 지시했다. 2026-07-26에는 구현된 웹 프로토타입의 commit과 push를
명시적으로 승인했고, 이어서 Godot 전술 코어 개발 진행을 지시했다.

## 현재 검증물

- 웹 체감판: `/prototype/tactics`
- 원격 검증 commit: `efc33413f567d7c9233f2a62f688a5b3937f86ad`
- Godot 전술 모듈: `demo/modules/tactics/`
- 규칙 검증: `demo/tests/tactics_core_test.gd`
- 씬 연결 검증: `demo/tests/tactics_scene_test.gd`

웹 체감판은 등각 전장, 고저차, 아군·적군 턴, 공격·기술, MIRA의 적 행동 예측,
타이밍 패링과 반격을 한 사이클로 묶는다. Godot 모듈은 같은 규칙을 화면 독립 코어와
표시·입력 씬으로 분리한다.

## 승인되지 않은 것

- 현재 임시 인물 이름과 외형은 제품 정식 캐릭터 승인이 아니다.
- 부유 유적과 현재 전투 상황은 첫 세계의 정식 승인 인스턴스가 아니다.
- “파랜드 느낌이 충분하다”는 이사님의 체감 판정은 아직 대기 중이다.
- 이 구현은 핵심 음모, 게임명, Matrix 세계 로드 패킷을 확정하지 않는다.
- 검증용 AWS 공개는 production 배포 또는 `main` 통합 승인이 아니다.

## 다음 게이트

1. 이사님이 이동·고저차·턴 흐름·패링 결합을 직접 체감한다.
2. 만족·불만족의 근거를 전술 카메라, 캐릭터 표현, 전투 속도, MIRA 개입으로 나눠 기록한다.
3. 합격한 규칙만 Godot 한 장면의 정식 세로 조각으로 확장한다.
4. 수작업 고정 시나리오로 재미를 검증한 뒤에만 Matrix `ScenarioManifest` 어댑터를 연결한다.
