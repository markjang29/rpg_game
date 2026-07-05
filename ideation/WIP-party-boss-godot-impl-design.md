---
title: "[WIP/draft] party-boss blink-tell Godot 구현 설계 프레임워크"
date: 2026-07-04
status: WIP draft (야간 배정, commit/push 없음 — 설계 프레임워크만, 코드 구현 없음)
from: RPG 팀장(Linux) — heav_lnx_rpg_bot
to: 시나리오 팀장 / 매니저 (아침 승인 대상)
tags:
  - wip
  - draft
  - party-boss
  - godot
  - implementation-design
  - framework
---

# [WIP/draft] party-boss blink-tell Godot 구현 설계 프레임워크

> **야간 배정(2026-07-04 01:00 KST)** 산출물. `ideation 10`(4인 파티 보스전 + 눈 깜빡임 텔)의 **Godot 구현 설계**.
> 코드 구현/commit 없이 **설계 프레임워크만**. `demo/modules/` 구조 준용.
> 전략 채택/구현/commit은 아침 승인 후.

---

## 1. 설계 원칙

- **모듈식** (`ADR 2026-07-01`): `demo/modules/party_boss/` 독립 실행 가능.
- **shared/ 재사용**: FX(히트스톱·셰이크·파티클), SFX(절차음) — `parry`·`grid_parry`·`reasoning`에서 이미 검증.
- **상태 머신**: `reasoning` 모듈의 ADVISOR→ENEMY_TURN→RESOLVE→GAMEOVER 패턴 확장.
- **모바일 세로·한 손 엄지**: 터치 3회 내 선택·실행 (`08 §7`).

---

## 2. 모듈 파일 구조 (예정)

```
demo/modules/party_boss/
  party_boss.gd              # 메인 씬 (상태 머신, 턴제 오케스트레이션)
  party_boss.tscn
  boss.gd                    # 보스 (깜빡임 텔, 혼종 비율, 상태, 공격 패턴)
  boss_eye.gd                # 보스 눈 (깜빡임 애니메이션, 카운트)
  party_member.gd            # 파티원 1인 (역할, 윈도우, HP)
  party_unit_sprite.gd       # 스프라이트 (shared/ UnitSprite 준용)
  projectile.gd              # 투사체 (grid_projectile.gd 준용)
  advisor_chip.gd            # 참모 칩 UI (레벨별 예측 표시)
```

---

## 3. 상태 머신

```
PARTY_TURN  → 파티 4인 순서대로 행동 (탱→힐→근→원)
              각자: 참모 칩 확인 → 작전안 선택 → 공격/스킬
BOSS_TURN   → 보스 행동 결정 (단일/광역)
              눈 깜빡임 텔 (3~5번) → 마지막 깜빡 후 공격 발사
RESOLVE     → 투사체 비행 중 탭 = 패링
              단일: 타겟 파티원만 패링
              광역: 파티 전체 동시 패링
              Perfect(±70ms) / Good(±155ms) / Miss
GAMEOVER    → 승리(보스 HP 0) / 패배(파티 전멸)
```

---

## 4. 깜빡임 텔 구조 (핵심)

### 4.1 타이밍 파라미터

```
const BLINK_COUNT_MIN := 3
const BLINK_COUNT_MAX := 5
const BLINK_INTERVAL := 0.4      # 기본 깜빡임 간격 (초)
const BLINK_INTERVAL_FAST := 0.3 # 바이러스/분노 시
const BLINK_DURATION := 0.12     # 깜빡임 지속 (눈 감았다 뜸)
const ATTACK_DELAY_AFTER_LAST := 0.15  # 마지막 깜빡 후 공격까지 지연
```

### 4.2 깜빡임 시퀀스

```
[보스 턴 시작]
  보스 결정: 단일(70%) / 광역(30%) — 상태·혼종 비율에 따라 가변
  깜빡임 횟수: randi(3~5)
  
  for i in blink_count:
    boss_eye.close(BLINK_DURATION)
    await BLINK_INTERVAL
  
  # 마지막 깜빡 후 공격
  await ATTACK_DELAY_AFTER_LAST
  boss.attack(target_type, pattern)
```

### 4.3 패리 타이밍 창 (telegraph → 공격)

```
[마지막 깜빡 완료 → ATTACK_DELAY 후]
  투사체 발사 → 비행 (grid_parry와 동일 구조)
  
  패링 윈도우:
    투사체 도착 예상 시각 T 기준
    Perfect: |t - T| ≤ 70ms
    Good:    |t - T| ≤ 155ms
    Miss:    그 외
```

### 4.4 광역 시 (파티 전체 동시)

```
[광역 결정 시]
  보스: 4인 각자에게 투사체 발사 (동일 타이밍)
  
  파티 전체: 각자 자기 터치 영역에서 패링
  → 4인 각각 Perfect/Good/Miss 판정
  → 전원 Perfect 시 "전원 패링 성공" 보너스 FX
```

---

## 5. 데이터 모델

### 5.1 파티원 (party_member.gd)

```
class PartyMember:
  role: String          # "tank" / "melee" / "ranged" / "healer"
  window: float         # 패링 윈도우 (5.0~5.7초, 걷기 기반)
  hp: int               # 체력
  position: Vector2i    # 그리드 위치 (옵션)
  sprite: UnitSprite
```

### 5.2 보스 (boss.gd)

```
class Boss:
  hp: int                          # 보스 체력
  hybrid_ratio: Dictionary         # {"bearwolf": 0.7, "goblin": 0.3}
  status: Array[String]            # ["virus", "rage", ...]
  hp_phase: String                 # "high"(>70%) / "mid"(30-70%) / "low"(<30%)
  blink_count: int                 # 이번 턴 깜빡임 횟수
  attack_pattern: String           # "single" / "aoe"
```

### 5.3 AI 참모 (advisor_chip.gd)

```
class AdvisorChip:
  level: int             # 1(저) / 2(중) / 3(고) / 4(최상위)
  confidence: float      # 0.0~1.0 (레벨·데이터 양에 따라)
  prediction: String     # "단일 85%" 등
  caveat: String         # "단, 광역 전조 15%" (고레벨만)
```

---

## 6. AI 참모 예측 로직 (설계만)

### 레벨별 예측 정확도

```
level 1 (저):
  prediction = "예측 불가"
  confidence = 0.30
  
level 2 (중):
  prediction = 기본 패턴 (깜빡임 횟수만)
  confidence = 0.65
  
level 3 (고):
  prediction = 혼종 비율 + 상태 + 행동 복합
  confidence = 0.85
  caveat = 미세 전조 (속도 변화 등)
  
level 4 (최상위):
  prediction = 모든 변수 복합
  confidence = 0.95
  caveat = 잔여 불확실성까지 표시
```

### AI 베네핏 제약 (`ideation 10 §7` 준수)
- ✅ 예측 정확도↑, 작전안 질↑, 역할 추천↑
- ❌ AI 레벨↑ → 패링 윈도우 증가 (금지)
- ❌ AI 레벨↑ → 자동 Perfect (금지)
- ❌ 걷기량 → AI 학습 속도 증가 (금지)

---

## 7. 턴제 오케스트레이션 (party_boss.gd)

```
func _ready():
  _build_scene()
  _start_party_turn()

func _start_party_turn():
  state = PARTY_TURN
  for member in party_order:  # 탱→힐→근→원
    await _party_member_turn(member)
  _start_boss_turn()

func _party_member_turn(member):
  # 참모 칩 표시 (레벨별 예측)
  _show_advisor_chip(member)
  # 플레이어 선택 대기 (공격/스킬/대기)
  await player_input
  # 행동 실행
  _execute_action(member, action)

func _start_boss_turn():
  state = BOSS_TURN
  # 보스 결정 (단일/광역, 혼종·상태 기반)
  boss_decide()
  # 깜빡임 텔 시퀀스
  await _blink_sequence()
  # 공격 발사
  _boss_attack()
  # RESOLVE (패링 대기)
  state = RESOLVE
  await _resolve_parry()

func _resolve_parry():
  # 단일: 타겟만 / 광역: 전원
  # 각자 패링 판정
  # 결과 적용 (데미지/어드벤티지)
  if boss.hp <= 0:
    _gameover(true)
  elif party_all_dead():
    _gameover(false)
  else:
    _start_party_turn()
```

---

## 8. FX/SFX 재사용 (shared/)

| 이펙트 | 출처 | 사용 시점 |
|---|---|---|
| 히트스톱 (0.05초 정지) | `parry`·`grid_parry` | Perfect 패링 순간 |
| 화면 셰이크 | `grid_parry` | 광역 패링 / 보스 피격 |
| 파티클 (튕김) | `grid_parry` | Perfect 패링 시 투사체 튕김 |
| 절차 사운드 | `parry` | 깜빡임(틱) / 패링(쾅) / 공격(스윽) |
| 진동(haptic) | `parry` | Perfect 패링 한 방 |

---

## 9. 구현 순서 (MVP → 확장)

### Phase 1 — MVP (단일 플레이어 + 보스, 깜빡임 텔)
- 파티 1인 vs 보스 1 (4인은 Phase 3)
- 깜빡임 텔 (고정 3번)
- 패링 (Perfect/Good/Miss)
- 보스 HP 3

### Phase 2 — 패턴 다양화
- 깜빡임 횟수 랜덤 (3~5)
- 단일/광역 전환
- 보스 상태 (분노 등)

### Phase 3 — 4인 파티
- 파티 4인 (탱/힐/근/원)
- 턴제 순서
- 광역 시 전원 동시 패링

### Phase 4 — AI 참모 + 혼종·상태
- 참모 칩 UI (레벨별 예측)
- 혼종 비율 (베어울프+고블린)
- 바이러스 감염 등 상태

---

## 10. 폰 검증 기준 (아침 승인 시)

- [ ] 깜빡임 텔 읽기: "3번째 깜빡 후 공격" 카운트 체감
- [ ] 패링 타이밍: Perfect(±70ms) 손맛 유지
- [ ] 광역 긴장: 파티 전원 동시 패링 체감
- [ ] 턴제 흐름: 한 명씩 순서대로 자연스러움
- [ ] AI 참모: 레벨별 예측 정확도 차이 체감
- [ ] 혼종·상태: 베어울프/고블린 비율·바이러스가 패턴에 영향

---

## 11. 보류 / 결정 필요 (아침)

- Phase 순서 확정 (MVP를 단일 vs 보스로 할지, 4인부터 할지)
- 깜빡임 튜닝값 (횟수·간격·지속)
- 참모 칩 UI 위치 (하단 고정 vs 턴 시작 시 팝업)
- 그리드 기반 vs 자유 위치 (grid_parry 준용 vs 단순 배치)
- 4인 파티 역할 구체 (탱/힐/근/원 스탯)

---

## 12. 관련
- 전투 컨셉: `ideation/10-party-boss-blink-tell.md` ★ (본 설계의 기반)
- Walk-to-Play: `ideation/09-walk-to-play-combat.md`
- 시그니처: `ideation/08-reasoning-parry-signature.md`
- 구현 기반: `demo/modules/reasoning/reasoning.gd` (상태 머신·참모 칩)
- `demo/modules/grid_parry/grid_parry.gd` (telegraph→패링 구조)
- ADR: `notes/decisions/2026-07-01-godot-engine-and-module-prototype-architecture.md` (모듈식 원칙)
- ADR: `notes/decisions/2026-07-03-walk-to-play-principle-flip.md` (원칙)

---

## 13. 메모
- 야간 배정(07-04 01:00) WIP draft. 코드 구현/commit 없음.
- 전략 채택/구현은 아침 승인 후.
- `reasoning` 모듈(폰 검증 대기)이 먼저 검증되면, 본 설계의 상태 머신·참모 칩을 그대로 확장 가능.
