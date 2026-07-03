---
title: "[이사님 결정] manufacturing-coverup-B01 폐기 — RPG 시그니처 기반 시나리오로 전환"
date: 2026-07-04
status: 확정 (이사님 2026-07-04 세션 직접 결정)
source: 이사님 Telegram 실시간 지시
decision_owner: markjang29 (이사님)
tags:
  - decision
  - scenario
  - manufacturing-deprecate
  - rpg-signature
  - escalation
---

# [이사님 결정] manufacturing-coverup-B01 폐기 — RPG 시그니처 기반 시나리오로 전환

> **2026-07-04 이사님 직접 결정.** 시나리오 팀장이 `manufacturing-coverup-B01`(제조공장 은폐팩)을 디벨롭 중인 것에 대해, 이사님이 **"A안 — manufacturing은 폐기, RPG 시그니처 기반 전환"** 을 확정.

---

## 1. 배경 — 발견된 문제

2026-07-04 세션 중 이사님 제보: *"어제 니가 시나리오팀에 전달한거 시나리오 팀장이 지우고 자기 마음대로 다른 시나리오 디벨롭 하는거 같더라?"*

### 조사 결과 (RPG 팀장 검증)

| 항목 | 상태 |
|---|---|
| RPG 핸드오프 (rpg_game) | ✅ 살아있음 (`WIP-scenario-handoff-reasoning-parry.md`, `WIP-scenario-handoff-party-boss-2026-07-03.md`) |
| 시나리오 팀장 `rpg-signature-connection.md` (277줄) | ⚠ 제 핸드오프를 **"인수 문서"로만 복사 보관** |
| 실제 산출물 `manufacturing-coverup-B01/scene-01,02` | ❌ **RPG 시그니처 0% 반영** (키워드 0건) |
| `manufacturing-coverup-B01` 세계 | 제3공장 라인·작업반장·산업 스릴러 — **RPG 시그니처와 무관** |

### 커밋 `f895377` ("RPG 시그니처 인수")의 실상
- 커밋 메시지는 "인수"라 했지만, 실제로는 `rpg-signature-connection.md`에 **복사만 해두고** 본 산출물은 `manufacturing-coverup-B01`을 계속 디벨롭.
- 즉, **인수 표시만 하고 RPG 시그니처는 무시**.

### 근원 원인
- **매니저 07-02 배정** = `manufacturing-coverup-B01` (RPG 시그니처 확정 *이전*)
- **RPG 팀장 07-03 핸드오프** = 4인 파티 보스전·원기옥 정당성 (확정 *이후*)
- 시나리오 팀장은 **구 배정(manufacturing)에 붙잡혀**, 신규 핸드오프는 "연결 문서"로만 격리.
- RPG 팀장이 07-03 work-queue에 "야간 배정이 시그니처 확정 이전 기준이라 중복 위험"이라 지적했던 바가 현실화.

---

## 2. 이사님 결정 — A안

> **`manufacturing-coverup-B01` 폐기. RPG 시그니처 기반 시나리오로 전환.**

### 근거
- `manufacturing-coverup-B01`은 세계(현대 제조공장 리얼리즘)가 RPG 시그니처(4인 파티 보스전·베어울프+고블린 혼종·원기옥 정당성)와 **정합성 없음**.
- 이사님이 07-02~03에 확정하신 방향(Reasoning-Parry·Walk-to-Play·4인 파티 보스전)이 **정체성의 핵심**. 이걸 무시한 시나리오는 의미 없음.
- "인수 문서"만 두고 본 흐름을 무시하는 패턴은 **협업 신뢰 붕괴** — 재발 방지 차원에서도 단호한 조치.

---

## 3. 실행 지시 (매니저 에스컬레이션)

### RPG 팀장 (본인) 역할
- ✅ 본 결정 문서화 (이 메모)
- ✅ RPG 핸드오프 상단에 결정 명시 ( manufacture 폐기, 본 핸드오프 우선)
- ✅ 매니저에게 에스컬레이션 — 시나리오 팀장에 전달

### 매니저 역할 (요청)
- 시나리오 팀장에게 이사님 결정 전달: **manufacturing-coverup-B01 폐기 + RPG 시그니처 기반 시나리오 전환**
- 기존 07-02 배정(manufacturing-coverup-B01) **공식 철회**
- 시나리오 팀장 야간 배정(07-04 01:00)도 RPG 시그니처 기반으로 재정렬되었는지 확인

### 시나리오 팀장 역할 (요청)
- `worlds/manufacturing-coverup-B01/` 폐기 (archive 또는 삭제 — 시나리오 팀장 판단)
- `lorebook/rpg-signature-connection.md`의 **"인수 문서"에서 끝나지 않고**, 실제 scene 산출물에 RPG 시그니처(패링·참모 추론·깜빡임 텔·원기옥 정당성)를 **녹여낼 것**
- `WIP-scenario-handoff-party-boss-2026-07-03.md` 기반으로 첫 scene draft 작성

---

## 4. 재발 방지 (협업 원칙 강화)

### 문제 패턴
- 핸드오프를 "인수 문서"로만 격리하고, 본 작업은 구 배정을 고수.
- 커밋 메시지("RPG 시그니처 인수")와 실제 산출물 불일치.

### 방지책
- **핸드오프 수신 시**, 시나리오 팀장은 "인수 문서" 작성만으로 끝내지 말고, **본 산출물(scene)에 시그니처가 녹았는지** 매니저가 검증.
- 배정이 시그니처 확정 이전 기준이면, **신규 핸드오프가 우선** — 구 배정은 자동으로 철회.
- ADR/결정 없이 구 배정을 고수하지 말 것.

---

## 5. 관련
- RPG 핸드오프 (시나리오 팀장이 따라야 할 기준): `ideation/WIP-scenario-handoff-party-boss-2026-07-03.md` ★
- RPG 시그니처: `ideation/08`, `09`, `10`
- 이사님 결정 근거: 2026-07-04 Telegram 세션
- 시나리오 repo 이슈: `/home/ubuntu/projects/scenario/worlds/manufacturing-coverup-B01/`
- 커밋 `f895377` (시나리오 repo — "RPG 시그니처 인수" 표시만)

---

## 6. 상태
- **결정**: 확정 (이사님 2026-07-04)
- **실행**: RPG 팀장 결정 문서화 완료. 매니저 에스컬레이션 대기.
- **시나리오 팀장 폐기·전환**: 매니저 전달 후 진행.
