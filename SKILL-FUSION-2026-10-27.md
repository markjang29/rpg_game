# 스킬 융합 2~4단 실행 보고 — 보안 점검 · 격리 POC (2026-10-27)

- 발령: 이사님 10-27 확정 통보(매니저 경유) — 10-23 RPG 봇 검수안 채택.
- 원장: notes `projects/agent-ops/proposals/2026-10-27-design-doc-kickoff.md` (commit `016f4cb`).
- 담당: aws-rpg. RELAY-64(설계 1차 승인 대기)와 충돌 없음 — 본 작업 선행, RELAY-64는 승인 후 재개.

## 1. 보안 점검 (2단) — 선별 대상 전수 스캔

대상 4종 원본을 임시 격리 디렉토리에 클론(업스트림 커밋 고정) 후 스캔:
네트워크 호출(`http/urllib/requests/socket/curl`), 자격증명(`api key/token/secret/environ`),
코드실행(`eval/exec/subprocess/os.system`), 프롬프트 주입(`ignore previous` 등), 훅(`SessionStart/PreToolUse`).

| 대상 | 업스트림 | 판정 | 근거 |
|---|---|---|---|
| awesome-gamedev `genres/rpg` | `184b72be` | ✅ 통과 | 순수 마크다운 플레이북. 매치 전무 |
| awesome-gamedev `disciplines/create-game-assets` | `184b72be` | ✅ 통과(조건) | 본체·scripts 클린. `agents/openai.yaml`(외부 API 인터페이스 정의) **제외 복사** |
| awesome-gamedev `godot/godot-gdscript` | `184b72be` | ✅ 통과 | 매치 전무 |
| awesome-gamedev `godot/godot-gdscript-headless-testing` | `184b72be` | ✅ 통과 | 매치 전무. `godot --headless` CI 게이팅 절차 문서 |
| sprite-gen 로컬 스테이지 | `419f02cd` | ✅ 통과(범위 한정) | AST 의존 폐쇄 분석으로 21모듈 확정 — **금지 영역 0포함 확인**: `gen/`(이미지젠 API·`env_api_key`), `audio/`(ElevenLabs API `ELEVENLABS_API_KEY`), `video/`(`rife_install` 외부 바이너리 다운로드)는 폐쇄 밖. 폐쇄 내 매치 전무(유일한 `subprocess`는 자기 재호출 heal) |
| game-studios 양식 3종(GDD·ADR·릴리스 체크리스트) | `05ad7c8a` | ✅ 통과 | 불변 마크다운 양식. hooks·에이전트 조직 미포함 |
| superpowers | `2ce8aa15` | 복사 없음 | 절차 사상만 `GAME-DEV-RULES-DRAFT-v1.md`로 재작성(아래 4-a) |

제외 확정: 업스트림 라우터·마켓플레이스 정의(`.claude-plugin/`), sprite-gen `SKILL.md`(API 중심 안내문),
create-game-assets `agents/`, game-studios `.claude/hooks`·조직 시뮬레이션 전체.

## 2. 격리 POC (3단) — `.claude/skills/` 선별 복사

구성(총 904K): `rpg-genre/` · `create-game-assets/` · `godot-gdscript/` ·
`godot-gdscript-headless-testing/` · `sprite-atlas-local/`(자체 SKILL.md + vendor 21모듈·엔트리 4종 + poc) ·
`game-doc-forms/`(자체 SKILL.md + 양식 3종). 상세 매니페스트는 `.claude/skills/README.md`.

무결성: 제3자 원문은 업스트림과 바이트 동일하게 유지(수정 없음), 자체 작성은 2건뿐.
훅·자동 설치·라우터 없음 — 프로젝트 국한(전역 아님).

### POC 실행 결과 — sprite-gen 로컬 파이프라인 (오프라인 입증)

입력: 합성 테스트 시트 512×768(2×2 격자, 순록 크로마 배경 `#00FF00`, 4프레임 bob 애니메이션).

```
[1/3] slice_sheet_cells.py  → poc/cells/f1..f4.png  (크로마킷 알파 추출, 프레임별 분리)
[2/3] unpack_atlas_run.py --pngs-dir → poc/run/     (run-dir 계약 생성, ok:true)
[3/3] compose_sprite_atlas.py --run-dir → atlas+manifest (ok:true)
```

**외부 API 호출 0 입증**: 전 스테이지를 `HTTP(S)_PROXY/ALL_PROXY=http://127.0.0.1:9`(폐쇄 포트) 환경에서
실행 — 네트워크 시도가 있었다면 실패해야 정상인데 전 단계 성공. 자격증명·환경변수 읽기 0(코드 스캔＋실행 입증).

산출 검증:
- `sprite-sheet-alpha.png` 1024×384 RGBA — 투명 240,477px / 불투명 151,191px(크로마 제거 정상)
- `manifest.json` — `frame_layout.rows.walk` 프레임 좌표 4개(x/y/w/h), `fps:2`, `durations_ms:[500×4]`,
  셀 규격 256×384 — 엔진(8009/godot-tactics)·asset workbench 스토어 이관에 필요한 계약 그대로
- `sprite-sheet-alpha.report.json` — 프레임별 불투명 픽셀수(예: frame0 37,336px)로 내용 존재 증명

미실행 스테이지(정직 기록): `extract`(row-strip→프레임, 픽셀 언페이크)는 이번 POC에서 다루지 않음 —
slice가 같은 크로마 알고리즘 계열을 검증했고 extract는 run 계약이 무거워 1차 POC에서 제외.
필요 시 2차에서 `prepare`+`extract` 경로 추가 검증.

## 3. 경계 준수 확인

- 제3자 SKILL.md 자동 설치 없음(수동 선별 복사만) · 훅 일괄 적용 없음 ✅
- 외부 API·자격증명 미사용 — 이미지젠 스테이지 미포함, 오프라인 실행 입증 ✅
- 토큰·키·서명URL 기록 없음(경로·커밋 해시만) ✅

## 4. 다음(4단)

- 4-a 게임개발 사칙 초안: `GAME-DEV-RULES-DRAFT-v1.md`(별도).
- 4-b 승인보드 후보 등록: approval-board `decisions.json` pending 안건(커밋과 연결).
