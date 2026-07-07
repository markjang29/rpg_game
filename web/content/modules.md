## 모듈식 프로토타입 개발

> 작은 모듈 단위 프로토타입 → 폰 검증 → 모듈 라이브러리 적립 → 본편 조립

### 개발 방식

각 메커니즘을 독립 실행 가능한 모듈(`demo/modules/<이름>/`)로 먼저 만든다
- 세부 수치 튜닝은 본편 조립 시점으로 미룬다
- 지금은 "작동·느낌 사는가?"까지만

### 모듈 현황

- ✅ **parry** — 패링 손맛 모듈 (검증 완료, 2026-07-01)
- 🟡 **walk** — 걷기 시스템 (예정)
- 🟡 **color-dye** — 색 염색 시스템 (예정)
- 🟡 **territory** — 영토/지역 시스템 (예정)
- 🟡 **romance** — 로맨스 시스템 (예정)

### 프로젝트 구조

```
rpg_game/
├── README.md
├── DEVELOPMENT.md          # 개발 방향·원칙
├── ideation/               # 기획 아이디에이션
└── demo/                   # Godot 프로젝트 (모듈 라이브러리)
    ├── project.godot
    ├── modules/            # 각 메커니즘 모듈 (독립 실행 가능)
    │   └── parry/          #   패링 손맛 모듈
    ├── shared/             # 모듈 공통 헬퍼 (FX, 사운드 재생기)
    ├── assets/             # 공통 에셋 (sfx 등)
    └── tools/              # 코드 생성 (사운드 합성 등)
```

<div class="highlight-box">
**엔진**: Godot 4.7 (GDScript, GL Compatibility) · **타겟**: 모바일 (Android 우선)
</div>
