# RPG Game

> 현재 최상위 제품 정본: **[RPG GAME 01 — 게임명 미정](projects/rpg-game-01/README.md)**
> 엔진: **Godot 4.7 (GDScript, GL Compatibility)** · 타겟: **모바일(Android 우선)**

## 상태

- **RPG GAME 01 핵심 컨셉 승격 완료** (2026-07-17) — 강제 세계 로드×관찰형 패링×불완전한 AI×걷기 예측 버퍼×멀티버스 연속성
- 게임명은 핵심 음모 결정 전까지 미정 — [`OPEN-conspiracy-and-title.md`](projects/rpg-game-01/decisions/OPEN-conspiracy-and-title.md)
- 컨셉 수렴 완료 — `ideation/06-concept-convergence.md`, `07-color-dye-walking-system.md`
- **모듈식 프로토타입 개발 진행 중** — `DEVELOPMENT.md` 참고
- 첫 모듈(패링 손맛) 폰 검증 완료 (2026-07-01)

## 개발 방식

> **작은 모듈 단위 프로토타입 → 폰 검증 → 모듈 라이브러리 적립 → 본편 조립**

상세 원칙·컨벤션은 **[`DEVELOPMENT.md`](DEVELOPMENT.md)** 에. 핵심만:
- 각 메커니즘을 독립 실행 가능한 모듈(`demo/modules/<이름>/`)로 먼저 만든다.
- 세부 수치 튜닝은 본편 조립 시점으로 미룬다 (지금은 "작동·느낌 사는가?"까지만).
- 모듈 현황: parry ✓ / walk·color-dye·territory·romance 예정

## 구조

```
rpg_game/
├── README.md
├── DEVELOPMENT.md          # 개발 방향·원칙
├── projects/
│   └── rpg-game-01/        # RPG GAME 01 제품 정본·결정·설계
├── ideation/               # 기획 아이디에이션·결정 이력 (01~11 및 WIP)
└── demo/                   # Godot 프로젝트 (모듈 라이브러리)
    ├── project.godot
    ├── modules/            # 각 메커니즘 모듈 (독립 실행 가능)
    │   └── parry/          #   패링 손맛 모듈
    ├── shared/             # 모듈 공통 헬퍼 (FX, 사운드 재생기)
    ├── assets/             # 공통 에셋 (sfx 등)
    └── tools/              # 코드 생성 (사운드 합성 등)
```

## 협업 규칙

여러 환경의 에이전트가 함께 작업한다 (Linux 서버 + Windows 머신, 같은 repo 공유).

1. 작업 전 반드시 `git pull`, 작업 후 즉시 `git push`.
2. 커밋 메시지는 변경 내용 명확히 (한국어 OK).
3. 중요 결정/설계는 이 repo의 `DEVELOPMENT.md`·`ideation/` 또는 `notes` 저장소(`github.com/markjang29/notes`)에 기록.
4. 바이너리 산출물(`export/`, `*.apk`, `*.keystore`, `.godot/`)은 커밋 금지.

RPG GAME 01 관련 신규 제품 결정은 `projects/rpg-game-01/`을 정본으로 한다. `ideation/`은 결정 이력과 근거 자료로 보존한다.

## 결정 이력

- 2026-06-25: 프로젝트 세팅
- 2026-06-26: 걷기×전술 RPG 컨셉 1안 수렴 (색 염색 시스템 포함)
- 2026-07-01: 엔진 Godot 4.7 확정 · 스토리(길 잇는/끊는 자) 폐기·재검토 · **모듈식 프로토타입 개발 방식 채택**
- 2026-07-17: 멀티버스 세계 로드·관찰형 패링·AI 안내자·걷기 예측 버퍼를 **RPG GAME 01**로 승격 · 게임명은 핵심 음모 결정 뒤 선정
