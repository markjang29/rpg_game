---
title: RPG GAME 01 기존 자료 상속 지도
date: 2026-07-17
status: canonical-index
project_id: rpg-game-01
---

# 기존 자료 상속 지도

기존 파일은 결정의 역사와 링크를 보존하기 위해 이동하지 않는다. 대신 아래 표가 **RPG GAME 01이 무엇을 상속하고 무엇을 전복·제외하는지** 판정하는 정본이다.

| 기존 자료 | RPG GAME 01에서의 역할 | 현행 판정 |
|---|---|---|
| `ideation/05-user-idea-walking-fitness-rpg.md` | 걷기 보상·접근성·P2W 방지의 사용자 원안 | 원칙 상속 |
| `ideation/06-concept-convergence.md` | 걷기×전술 RPG의 초기 수렴 | 일부 상속. 걷기 전투 0기여 절대 규칙은 후속 결정으로 전복됨 |
| `ideation/07-color-dye-walking-system.md` | 걷기 기반 표현·코스튬 보조축 | 제품 핵심은 아님. 후속 검토 대기 |
| `ideation/08-reasoning-parry-signature.md` | 불완전한 AI 추론×플레이어 판단×패링 | 핵심 상속 |
| `ideation/09-walk-to-play-combat.md` | 걷기 자원을 반응 여유와 연결 | 핵심 상속, RPG01에서는 `prediction_buffer` 방향으로 정제 |
| `ideation/10-party-boss-blink-tell.md` | 눈·움직임 관찰과 보스 텔 | 관찰 전투 근거로 상속. 구체 인스턴스는 자동 채택 안 함 |
| `ideation/11-advisor-score-system.md` | AI 안내자 평가·성장 아이디어 | AI 성장 근거로 상속, 수치/보상은 재검증 |
| `ideation/DRAFT-matrix-scenario-factory-request.md` | 매트릭스↔RPG 자산 경계의 선행안 | 방법론 상속, 현황·고유번호는 최신 정본 재검증 필요 |
| `ideation/PRINCIPLE-instance-requires-director-confirm.md` | 구체 인스턴스 도입 전 이사님 체감·승인 | 상위 불변 원칙 |
| `ideation/DECISION-2026-07-04-manufacturing-deprecate.md` | 무관한 제조공장 은폐 시나리오 폐기 | **제외 결정 유지** |
| `demo/modules/parry/` | 기존 패링 손맛 프로토타입 | 구현 자산으로 상속 가능, RPG01 맥락의 재검증 필요 |
| `demo/modules/grid_parry/` | 그리드×텔레그래프 패링 프로토타입 | 구현 자산으로 상속 가능, 전투 구조 결정 전 결합 보류 |
| `demo/modules/reasoning/` | AI 추론×플레이어 결정 프로토타입 | 핵심 실험 자산, RPG01 관찰 UI에 맞춰 재검증 |

## 우선순위 규칙

충돌할 때는 다음 순서로 판정한다.

1. 이사님의 최신 직접 결정.
2. `projects/rpg-game-01/decisions/`의 승인 문서.
3. `projects/rpg-game-01/design/`의 현행 설계.
4. 이 상속 지도.
5. 기존 `ideation/` 및 WIP 문서.

기존 문서의 “확정” 표시는 당시 기준의 상태다. RPG GAME 01 정본과 충돌하면 자동으로 현행 결정이 되지 않는다.
