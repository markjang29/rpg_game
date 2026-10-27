---
name: game-doc-forms
description: >
  게임 개발 문서 양식 3종(GDD·ADR·릴리스 체크리스트) 사용 가이드.
  새 게임 시스템을 설계하거나(GDD), 기술 선택을 기록하거나(ADR), 출시 전 점검(릴리스)이 필요할 때 사용.
  양식 자체는 Claude-Code-Game-Studios에서 차용(문서 양식만 — 조직 시뮬레이션·훅은 미사용).
---

# game-doc-forms (문서 양식만 차용)

이사님 10-27 확정: "Game Studios는 GDD·ADR 등 문서 양식만 차용".
우리 절차(설계 1차 → 이사님 승인 → 자체 테스트 → 검수)에 맞춰 쓴다.

## 양식 3종 (references/)

- `game-design-document.md` — 신규 시스템·기능 설계서. 이사님 설계 1차 승인 안건의 본문 양식으로 쓴다.
- `architecture-decision-record.md` — 기술 결정 기록(ADR). status는 우리 상태값(pending/approved 등)을 그대로 보존.
- `release-checklist-template.md` — 배포 전 점검. 8009/8017 배포 시 `deploy/` 절차와 함께 사용.

## 사용 규칙

1. 양식을 채운 산출물은 rpg_game Git에 커밋한다(대화 기억은 정본이 아님).
2. 승인 상태는 승인보드·notes 원장에서만 바뀐다 — 문서 스스로 "확정"을 선언하지 않는다.
3. 양식 파일 자체는 업스트림 스냅샷(수정 금지), 새 문서는 references 밖에 작성한다.
