# DEVELOPMENT.md — 개발 방향 & 원칙

> 확정: 2026-07-01 (이사님 결정) · 엔진: **Godot 4.7 (GDScript, GL Compat)** · 타겟: **모바일(Android 우선)**

---

## 0. 핵심 원칙 — 모듈식 프로토타입 개발

> *"작은 모듈로 테스트 → 폰에서 검증 → 여러 개 만들어두고 필요할 때 가져다 쓴다."*

본편을 한 번에 짜지 않는다. 게임의 각 메커니즘(전투 손맛, 걷기, 영토, 로맨스 등)을 **독립된 실행 가능한 모듈**로 먼저 프로토타입하고, 폰에서 "느낌"을 검증한 뒤 **모듈 라이브러리**에 적립한다. 충분한 모듈이 검증되면 본편(통합 씬)에서 조립한다.

### RPG GAME 01 제품 정본과 모듈의 관계

- 제품의 세계관·서사·캐릭터·시스템 결정은 [`projects/rpg-game-01/`](projects/rpg-game-01/README.md)에 기록한다.
- `demo/modules/`는 제품 결정의 체감을 검증하는 독립 실험장이다. 모듈이 작동한다는 이유만으로 RPG GAME 01 본편 채택이 되지는 않는다.
- 기존 `ideation/`의 현행 여부는 [`projects/rpg-game-01/legacy-source-map.md`](projects/rpg-game-01/legacy-source-map.md)에서 판정한다.
- RPG GAME 01의 구체 세계·캐릭터 인스턴스는 이사님 체감·승인 전 구현 입력으로 고정하지 않는다.

### 왜 이렇게 하는가
- **손맛/체감은 머리로 설계되지 않는다** — 폰에서 만져봐야 안다. 작은 루프를 빨리 폰에 올려 검증.
- **재사용** — 한 번 만든 모듈(FX 시스템, 판정 로직, 사운드 합성 등)은 본편 어디든 끌어다 쓴다.
- **리스크 분산** — 전체를 짜다가 "재미없다"가 나오면 잃는 게 크다. 모듈 단위면 버리거나 갈아엎어도 잃는 게 작다.

### 튜닝 철학 (지금 vs 나중)
- **지금 단계(모듈 프로토타입)**: "작동하는가? 느낌이 대략 사는가?"까지만.
- **나중(본편 조립 시점)**: 속도·수치·이펙트 강도 등 세부 튜닝. 그때 폰 피드백 기반으로 잡는다.
- ⇒ 수치 튜닝에 지금 매달리지 않는다. 대신 값을 한 곳(`_TUNE` 상수 블록 등)에 모아둬서 나중에 한 번에 잡는다.

---

## 1. 모듈 정의

하나의 "모듈" = **독립적으로 실행·검증할 수 있는 단일 씬**.

- 진입 씬 1개 (`<module>.tscn`) — 단독 실행하면 그 메커니즘만 체험 가능
- 자체 로직 스크립트 — 외부 모듈에 의존하지 않음 (공통 헬퍼는 `shared/` 사용 OK)
- `_TUNE` 블록 — 튜닝값 상단 집중 배치 (나중에 한 번에 조정)
- 가능하면 절차적 에셋(primitive, 셰이더, 합성 사운드) — 외부 에셋 의존 최소

---

## 2. 디렉토리 구조

```
rpg_game/
├── README.md
├── DEVELOPMENT.md          # 이 파일
├── .gitignore
├── projects/
│   └── rpg-game-01/        # 제품 정본·결정·설계·백로그
├── ideation/               # 기획 아이디에이션·결정 이력 (01~11 및 WIP)
├── demo/                   # Godot 프로젝트 (모듈 라이브러리 + 본편)
│   ├── project.godot
│   ├── export_presets.cfg
│   ├── modules/            # ← 각 메커니즘 모듈 (독립 실행 가능)
│   │   └── parry/          #   패링 손맛 모듈 (✓ 첫 모듈)
│   ├── shared/             # ← 모듈 간 공통 헬퍼 (FX, 사운드 재생기 등)
│   ├── assets/             # 공통 에셋 (sfx, sprites)
│   ├── tools/              # 코드 생성 스크립트 (사운드 합성 등)
│   ├── icon.svg
│   └── debug.keystore      # (gitignore — 서명키)
└── docs/                   # (필요시) 설계 문서
```

### 모듈 추가 컨벤션
- 새 모듈은 `demo/modules/<이름>/` 아래에.
- 진입 씬은 `demo/modules/<이름>/<이름>.tscn`.
- 모듈 안의 값은 `project.godot`의 `run/main_scene`을 바꿔가며 테스트 (또는 본편 씬에서 씬 전환).
- 공통으로 쓰이게 된 헬퍼는 `shared/`로 승격 (처음엔 모듈 안에 두다가 겹치면 올림).

---

## 3. 검증 루프 (모듈 → 폰)

```
모듈 구현 → 헤드리스 import 확인 → APK 빌드 → 서버 링크/전송 → 폰에서 느낌 → 메모/튜닝값 조정
```

빌드 명령 (서버):
```bash
export ANDROID_HOME="$HOME/tools/android-sdk"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$HOME/tools:$PATH"
cd /home/ubuntu/projects/rpg_game/demo
godot --headless --import            # 에러 체크
godot --headless --export-debug "Android" export/<Module>.apk
```

배포: APK 크기 50MB 이하면 cokacdir Telegram 전송, 초과면 서버 HTTP 링크(`python3 -m http.server 80`, 공개 IP).

---

## 4. 모듈 현황

| 모듈 | 상태 | 진입 | 비고 |
|---|---|---|---|
| **parry** (패링 손맛) | ✓ 작동·폰 검증 | `modules/parry/` | Perfect/Good/Miss 판정 + 히트스톱·셰이크·파티클·절차 사운드 |
| **grid_parry** (그리드×패링) | ✓ 작동·폰 검증 | `modules/grid_parry/` | 5×6 그리드 턴 전술 + telegraph 예고 + 패링. `shared/` FX·SFX 재사용 첫 사례 |
| **reasoning** (추론×전술) ⭐ | 🔨 진행 | `modules/reasoning/` | **시그니처 모듈**: 참모 추론 보고서 + 전제(목표함수) 토글 + 토큰 3단계 + 패링(손). `grid_parry` 위에 추론 레이어 얹음 (B안, `ideation/08` 참조) |
| walk (걷기=재화) | 예정 | — | 3겹 캡, 입장 재화 (컨셉 수렴参照) |
| color-dye (색 염색) | 예정 | — | 마비노기풍 표현층, 전투력 0 기여 |
| territory (영토PvP) | 예정 | — | 진영 분기 (서사는 재검토 중) |
| romance (로맨스) | 예정 | — | |

---

## 5. 협업 규칙 (기존 README와 동일)

- 작업 전 `git pull`, 작업 후 즉시 `add/commit/push` (Windows 에이전트와 repo 공유).
- 커밋 메시지: 변경 명확히 (한국어 OK).
- 결정/진행은 `notes` 저장소에 기록.
- 바이너리 에셋·빌드 산출물(`export/`, `*.apk`, `*.keystore`, `.godot/`)은 커밋 금지.
