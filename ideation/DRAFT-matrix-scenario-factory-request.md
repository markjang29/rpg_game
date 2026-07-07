---
title: "[DRAFT v4] 매트릭스 — RPG 클라이언트 명세 (고유번호 매핑 + 인스턴스 완전 폐기)"
date: 2026-07-07
status: DRAFT v4 (시나리오팀 고유번호 체계 도입 + 보완 3점 반영. 송신은 매니저 승인 후)
revision: v1 → v2(특정 인스턴스 채택 권장 — R1·R3 위반) → v3(격하·컨펔 게이트) → v4(해당 인스턴스 완전 폐기 + 고유번호 매핑 체계 도입 + 시나리오팀 보완 3점 반영)
from: RPG 팀장(Linux) — heav_lnx_rpg_bot (클라이언트)
to: 시나리오팀 (heav_lnx_scenario_bot) — 서포터 + 매니저 (승인)
decision_source: 이사님 2026-07-07 — "시나리오팀 구조 다시 만들어" + "방법론 단계에 인스턴스 전제 말고 상위 규칙" + "자산은 고유번호로 매핑" + 인스턴스/세계관 후보 폐기
top_principle: ideation/PRINCIPLE-instance-requires-director-confirm.md (R1 층위분리·R2 전제금지·R3 공감선행)
asset_id_system: scenario/decisions/2026-07-07-asset-id-system.md (CHR/MOD/PRM/META/SCN/DRF-NNNN)
references:
  - scenario repo ADR 2026-07-07-scenario-asset-factory.md
  - scenario repo decisions/2026-07-07-asset-id-system.md
  - scenario repo drafts/matrix-meeting-2026-07-07.md
  - scenario repo drafts/reply-rpg-matrix-spec-2026-07-07.md
  - scenario repo tools/scenario-generator/DESIGN.md
tags:
  - draft
  - matrix
  - rpg-client-spec
  - methodology
  - asset-id-mapping
  - director-confirm-gate
---

# [DRAFT v4] 매트릭스 — RPG 클라이언트 명세

> **본 명세는 방법론·프로세스 층위만 다룬다.** 구체 자산 인스턴스(이름·설정)는 **고유번호 매핑**으로 처리 — RPG는 역할/function 서술, 시나리오팀이 자산 고유번호(`CHR/MOD/META-NNNN`)로 매핑. 인스턴스는 이사님 체감·컨펔 전에 방법론에 끌어오지 않는다(상위 원칙 R1·R3).
> **v4**: v3의 "격하" 처리를 넘어 해당 인스턴스(과거 RPG 참모 후보) **완전 폐기** + 시나리오팀 고유번호 체계 도입 + 시나리오팀 검토 회신 보완 요청 3점 반영.

---

## 0. 전제 — 매트릭스(시나리오팀) 구조 + 고유번호 체계

> 아래 전제 교차 검증은 시나리오팀 몫.

- **정체성**: 매트릭스 = 제품용 자산 공장 (이사님 07-07 ADR). scenario-generator **v5 동작 중** (FastAPI 8003 + Oracle 23ai + GLM, 5단계 파이프라인, 웹 UI).
- **4대 축**: ① 인증 자산 뱅크 ★(최우선) ② 제품 포맷 익스포트 ③ 의뢰 인터페이스 ④ 자산 종류 확장.
- **자산**: 602점, `.extract/` 실제 내용 기반. RisuAI+로컬LLM 생태계(캐릭터카드·로어북·프롬프트·모듈).
- **★ 고유번호 체계 (이사님 옵션 2, 2026-07-07)** — 상세 `scenario/decisions/2026-07-07-asset-id-system.md`:
  - `CHR-NNNN`(캐릭터) · `MOD-NNNN`(모듈) · `PRM-NNNN`(프롬프트) · `META-NNNN`(**메타 자산** — 자산을 만드는 자산: 페르소나·생성기) · `SCN-NNNN`(시나리오/실험 산출물) · `DRF-NNNN`(draft, 이사님 컨펔 전).
  - 602점 전량 역추적 ID 부여, `catalog/index.json` + DB `assets` 양쪽 등록, `rpg_asset_mapping` 테이블 준비 완료.
  - **상태 전이**: `DRF-NNNN`(draft) → 이사님 컨펔 → `CHR/MOD/META-NNNN`(진열장) → RPG 이식(`rpg_asset_mapping` 기록).
- **자산 카드 스키마(매트릭스 회의 안건 2)**: `identity_kernel`/`negative_traits`/`diff_from_similar` + 임베딩 중복검사 + LLM judge.
- **4축 태깅(안건 1)**: worldview/emotion/structure/**function** ← RPG는 function 축으로 발굴.
- **RPG 포지션**: 매트릭스의 **클라이언트**. 본 명세 = 축 ③(의뢰) + 축 ②(익스포트 수신) + 이사님 안건 B 제안.
- **보완 ① 해결 (메타 자산)**: 시나리오팀 회신이 지적한 "캐릭터 만드는 자산도 있다(2층 메타 자산)" → 시나리오팀이 `META-NNNN`으로 자체 체계화 완료. 본 명세는 별도 레일(C) 없이 `META-NNNN` 체계를 참조.

---

## 1. 정기 의뢰 루틴 (축 ③) — 고유번호 매핑 방식

> 이사님이 정하신 두 레일(방향 1 참모 + 방향 4 오늘의 전설). **RPG는 역할/function + 주제로 요청, 시나리오팀이 고유번호로 매핑.** 프로세스만 명세.

### 1.1 레일 A — 참모 자산 (방향 1)
- **발굴 방식**: 자산 뱅크 **function 축**(참모형 서포터)에서 RPG가 주제("공격형 참모" 등)로 후보 요청 → 매트릭스 DISCOVER가 후보를 **고유번호**(`CHR-NNNN`)로 제시 → RPG가 검토.
- **의뢰 템플릿**(RPG → 매트릭스): "참모 편향 유형 X. 보스 Y에 대한 추론/정정/관계반응 대사. `identity_kernel` 필수." → 시나리오팀이 `CHR-NNNN` 후보 응답.
- **주기**: 월간 — 기존 참모 대사 확장 + 신규 후보 발굴 요청.
- **게이트**: 후보 자산이 RPG에 들어오려면 **이사님 체감·컨펔** 선행 (§6). `DRF` → 컨펔 → `CHR`.

### 1.2 레일 B — 보스/씬 자산 (방향 4, 오늘의 전설)
- **주간 의뢰**: 보스 1~2종. RPG가 주제/메커니즘 제약(혼종 비율·상태·깜빡임 패턴) 제공 → 매트릭스가 서사 입혀 반환(`CHR-NNNN`).
- **포맷**: 매트릭스 기존 deliverable(**첫 보스 자산** — 역할 기반 익명화)이 레일 B 표준 포맷 선례.
- **의뢰 템플릿**(RPG → 매트릭스): 보스 컨셉 + 혼종/상태(전투 메커니즘) + "원래 정체"(정당성) + 처치/봐줄 분기.

---

## 2. 익스포트 포맷 (축 ② — 수신 방법) — 방법론 ★

> 이사님 "수신 방법 논의 필요" 지적. RPG "수신" = 시나리오팀 **축 ② 익스포트 파이프라인**. RPG가 받을 포맷/필드 명세(구체 자산 비의존).

### 2.1 핵심 원칙 — 서사층(시나리오팀) × 전투층(RPG) 분리

| 계층 | 작성자 | 필드 | 게임 효과 |
|---|---|---|---|
| **서사층** (정체성) | 시나리오팀 | `identity_kernel`·`negative_traits`·`diff_from_similar`·대사·말투·버릇 | **풍미 only** — 전투 숫자 0 기여 |
| **전투층** (메커니즘) | RPG 팀장 | 편향 계수(0.66×)·윈도우·패턴 수치 | 시그니처 정합 |

→ 시나리오팀은 서사층만, 전투 숫자는 RPG가 채운다/고정한다. 시나리오팀이 실수로 전투 밸런스를 건드리지 않음(`08 §5` 위반 방지). "생각천재·패션잼병"의 조직적 실천.

### 2.2 자산 → Godot 익스포트 (공통 구조)
```
asset_id: "<CHR-NNNN 등 고유번호>"
# 서사층 (시나리오팀)
identity_kernel / negative_traits / voice{...} / intro / tell_narrative / endings
# 전투층 (RPG)
rpg_mechanics: { risk_multiplier, window, hybrid_ratio, status, blink_count, ... }
```
- **프로토타입**: JSON. **본편**: Godot .tres (엔진/백엔드 ADR 후).

---

## 3. 이사님 안건 B 제안(RPG 입장) — 이식 "정체성 불변 조건" — 방법론 ★

> 매트릭스 회의록 이사님 결정 안건 B: "자산→제품 이식 시 원본 정체성 불변 조건 — 제품(RPG) 조정 필요". **RPG 제안** (보완 ③: '답변'→'제안' 표기 — 이사님 최종 결정 안건).

### 3.1 RPG 입장: 매트릭스 내 한정이 아니라 **RPG 이식 시에도 불변 조건 강제** 지지
- "자산의 실제 내용 사용"이 제품 단까지 살아야 — 평균화·복붙 방지는 이식까지 확장해야 의미.

### 3.2 쌍방 불변 조건 (맞교환 구조)
- **시나리오팀 → RPG**: 자산의 `identity_kernel`·`negative_traits`를 RPG가 위반하는 게임 메커니즘 부여 ❌.
- **RPG → 시나리오팀**: RPG가 추가하는 메커니즘(관계·엔딩 분기 등)은 **"전투 숫자(판정/위험/윈도우)에 0 기여, 풍미 only"** 약속.
- → **서사 풍미는 폭발, 전투 밸런스는 보존.** (구체 자산 예시는 이사님이 컨펔한 인스턴스에 적용 — §6 게이트 통과 후.)

---

## 4. RPG 시그니처 정합 룰셋 — 매트릭스 LLM judge + 야간 다듬기 파이프라인에 통합 — 방법론 ★

> 시나리오팀이 자동 품질관리(LLM judge·임베딩) + **야간 다듬기 파이프라인(매일 23:00, 이사님 07-07 안건 4)** 운영 중. RPG가 **이식용 자산 검증 룰셋**을 제공 → 시나리오팀 judge 프롬프트 **및 야간 다듬기에 통합** → 납품 전 자동 검증 (시나리오팀 추가 제안 수용).

RPG 이식 **거부 조건** (자산이 아래 위반 시 반송):
1. **걷기→사고(추론 품질) 기여** 암시 — 정체성 "생각 천재" 붕괴 (`09 §7`).
2. **PvP에서 걷기→윈도우/전투력 기여** — PvP 정규화 위반 (`09 §5`). (단, **PvE에서 걷기→윈도우는 Walk-to-Play로 허용** — `09` 전복 원칙.)
3. **참모가 정답·최적해 제시** (편향/누락 없는 완벽 보고서) — 오토배틀러화 (`08 §5`).
4. **편향 수치 비일관** (참모마다 무질서).
5. **정당성 부재** — 보스에 "원래 정체/오염 피해자" 서사 없음.
6. **불변 조건 위반** — `negative_traits`를 RPG 메커니즘이 깨는 조합.

> ★ 갱신: v3 거부조건 1 "걷기→전투력 기여"는 `09` Walk-to-Play 전복으로 좁혀짐 — 걷기→**사고** 기여(1)와 **PvP** 걷기→전투력(2)만 거부. PvE 걷기→윈도우는 현행 허용.

---

## 5. 정기 사이클 (매니저 cron 배정 대상)

| 주기 | 레일 | 산출 | 비고 |
|---|---|---|---|
| 주간 | B | 보스 1~2 (오늘의 전설) | 첫 보스 자산 포맷 준용(익명화) |
| 월간 | A | 참모 대사 확장 + 신규 후보 발굴 | function 축, §6 게이트, `CHR-NNNN` 매핑 |

---

## 6. ★ 인스턴스 컨펔 게이트 (상위 원칙 R1·R3) + 고유번호 상태 전이

> **구체 자산 인스턴스는 이사님 체감·컨펔 전에 방법론/채택 안건에 끌어오지 않는다.** 고유번호 체계의 상태 전이로 실천: `DRF-NNNN`(draft) → 이사님 컨펔 → `CHR/MOD/META-NNNN`(진열장) → RPG 이식(`rpg_asset_mapping` 기록).

### 6.1 게이트 절차
1. 시나리오팀이 후보 자산 `DRF-NNNN` draft 생산.
2. **이사님께 체감 가능하게 소개** (장면/한 줄 정의 — show, don't tell). 방법론 자리가 아닌 **별도 세션**.
3. 이사님 공감·컨펔.
4. 컨펔 시 `DRF` → `CHR/MOD/META`로 승격, `rpg_asset_mapping`에 기록, 레일 A/B 슬롯 진입 → §2·§3 불변 조건 적용.

### 6.2 폐기 인스턴스 (재발 방지 기록)
- 과거 RPG 참모 후보 1건(`DRF` 상태) — 이사님 미공감으로 **2026-07-07 완전 폐기**. v4에서 명세·revision에서 인스턴스 언급을 완전 제거. 동일한 R1·R3 위반(이사님 미공감 인스턴스를 방법론에 전제) 재발 방지.
- RPG 보스/파티 캐릭터 인스턴스도 동일 원칙 — 본 명세는 역할/function(`탱커/힐러/근딜/원딜/참모 AI/첫 보스`)으로만 서술, 구체 자산은 시나리오팀 고유번호 매핑 + 이사님 컨펔 후 이식.

---

## 7. 보류 / 결정 필요 (매니저 승인)

1. **안건 B** — 불변 조건 RPG 강제 + 역방향(전투 0기여) 맞교환 (이사님 최종 결정 — §3).
2. **익스포트 포맷** — JSON(프로토타입)/.tres(본편) 확정 (RPG + 시나리오팀).
3. **서사층·전투층 분리 원칙** 시나리오팀 자산 카드 스키마에 반영 합의 (§2.1).
4. **RPG 시그니처 룰셋(§4)** 시나리오팀 LLM judge + 야간 다듬기 통합 합의.
5. **고유번호 매핑 운용 규칙** — `rpg_asset_mapping` 갱신 주기·책임 (RPG-시나리오팀).
6. **송신 타이밍** — 본 명세 시나리오팀 전달 시점 (매니저 승인 후).
7. **§0 전제 교차 검증** — 매트릭스 구조 + 고유번호 체계 정확성 시나리오팀 확인.

---

## 8. 관련

- 상위 원칙: `ideation/PRINCIPLE-instance-requires-director-confirm.md` (R1·R2·R3)
- 자산 고유번호 체계: `scenario/decisions/2026-07-07-asset-id-system.md`
- 시나리오팀: `scenario/decisions/2026-07-07-scenario-asset-factory.md` · `scenario/drafts/matrix-meeting-2026-07-07.md` · `scenario/drafts/reply-rpg-matrix-spec-2026-07-07.md` · `scenario/tools/scenario-generator/DESIGN.md`
- RPG 시그니처: `ideation/08-reasoning-parry-signature.md` · `09-walk-to-play-combat.md` · `10-party-boss-blink-tell.md`
- 첫 보스 의뢰: `ideation/SCENARIO-REQUEST-first-boss-reasoning-parry.md`
- 핸드오프 원칙: memory `handoff-intake-not-enough`

---

## 9. 메모

- 본 파일은 **DRAFT v4** (해당 인스턴스 완전 폐기 + 고유번호 매핑 체계 도입 + 시나리오팀 보완 3점 반영). 2026-07-07.
- 방법론(본 명세 §1~§5)과 구체 인스턴스(§6 게이트)의 층위 분리가 핵심 — 상위 원칙 준수.
- 외부 송신(시나리오팀)은 매니저 승인 후.
