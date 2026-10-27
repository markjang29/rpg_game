# 게임 개발 스킬 격리 POC — 선별 융합 (2026-10-27)

- 근거: 이사님 10-27 확정(매니저 경유 통보) — notes `projects/agent-ops/proposals/2026-10-27-design-doc-kickoff.md` (commit `016f4cb`)
- 검수: RPG 봇 10-23 정독 검수안 채택 — **통짜 설치 반대 · 선별 융합**
- 담당: aws-rpg · 상태: 격리 POC(승인보드 후보 등록 완료, 승인 대기)

## 경계 (이사님 지시 — 위반 시 즉시 중단)

1. 제3자 SKILL.md **자동 설치 금지** — 이 디렉토리는 수동 선별 복사본이며 업스트림
   플러그인·마켓플레이스·라우터와 무관. `agents/openai.yaml`, hooks, SessionStart 주입 일체 미포함.
2. **외부 API·자격증명 미사용** — 이미지젠·사운드젠 API 스테이지는 제외.
   sprite-gen은 로컬 파이프라인(크로마 추출·슬라이스·아틀라스 합성)만 벤더.
3. 토큰값은 어떤 기록에도 남기지 않는다(경로만 기재).

## 선별 내역 (업스트림 커밋 고정)

| 디렉토리 | 출처 | 업스트림 커밋 | 검수 |
|---|---|---|---|
| `rpg-genre/` | gamedev-skills/awesome-gamedev-agent-skills `skills/genres/rpg` | `184b72be` | 통과 — 순수 마크다운, 네트워크·훅·자격증명 0 |
| `create-game-assets/` | 같은 저장소 `skills/disciplines/create-game-assets` | `184b72be` | 통과 — `agents/openai.yaml` 제외(외부 API 인터페이스 정의) |
| `godot-gdscript/` | 같은 저장소 `skills/godot/godot-gdscript` | `184b72be` | 통과 |
| `godot-gdscript-headless-testing/` | 같은 저장소 `skills/godot/godot-gdscript-headless-testing` | `184b72be` | 통과 |
| `sprite-atlas-local/` | aldegad/sprite-gen 로컬 스테이지 21모듈 + 엔트리 4종 | `419f02cd` | 통과 — 의존 폐쇄 분석으로 `gen/`(이미지젠 API), `audio/`(ElevenLabs API+키), `video/`(외부 바이너리 다운로드) 미포함 확인. SKILL.md(업스트림)는 API 중심이라 미복사, 자체 작성 |
| `game-doc-forms/` | donchitos/claude-code-game-studios `.claude/docs/templates/` 3종(GDD·ADR·릴리스 체크리스트) | `05ad7c8a` | 통과 — 양식 문서만, hooks·에이전트 조직은 미포함 |

superpowers(obra, `2ce8aa15`)는 **복사 없음** — 절차 사상(증거검증·체계적 디버깅·브레인스톤→계획)만
`GAME-DEV-RULES-DRAFT-v1.md`(repo root)로 재작성.

## SKILL.md 무결성

- awesome 4종·game-studios 양식 3종: 업스트림 원문 그대로(바이트 동일) 복사.
- `sprite-atlas-local/SKILL.md`, `game-doc-forms/SKILL.md`: 자체 작성(한국어).

## 로컬 파이프라인 사용(POC 검증됨)

```bash
cd .claude/skills/sprite-atlas-local
.python/bin python vendor/scripts/slice_sheet_cells.py --sheet IN.png --out-dir CELLS/ --chroma-key "#00FF00" --grid 2x2
.python/bin python vendor/scripts/unpack_atlas_run.py --pngs-dir CELLS/ --state-name walk --out-dir RUN/
.python/bin python vendor/scripts/compose_sprite_atlas.py --run-dir RUN/
# → RUN/sprite-sheet-alpha.png + RUN/manifest.json
```

- 외부 호출 0 검증: `HTTP(S)_PROXY`를 폐쇄 포트로 걸고 전 스테이지 실행 → 성공(오프라인 순수 입증).
- 세부 기록: repo root `SKILL-FUSION-2026-10-27.md` §POC.
