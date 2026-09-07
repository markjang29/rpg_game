# PROJECT-RULES — rpg_game 운영 규칙 (RPG 팀장)

- 발효: 2026-09-07 (이사님 지시) · 정리: 2026-09-08 aws-rpg
- 성격: 전 봇 공통 사칙(진입점·정보갱신·폴링·대화·진행보고·관제 허브)의 rpg_game 운용 반영.
  **원본 정본은 Notes Git이며, 이 파일은 정본 요약 + 이 repo 적용 노트다.** 충돌 시 정본이 우선.
- 등록: notes `projects/agent-ops/actors.json` → aws-rpg `required_refs: rpg_game:project-rules`

## 정본 (읽는 순서)

1. notes `principles/entrypoint-comms-progress-rules-v1.md` — 진입점·정보갱신·폴링·대화·진행보고 사칙
2. notes `projects/agent-ops/conversation-rules-v1.md` — 대화·소통 규칙
3. notes `projects/agent-ops/policy-index-v1.json` — 정책 인덱스(주소·문서 원장)
4. notes `projects/agent-ops/gwanje-hub-rest-queue-v1.md` — 관제 허브 v1 정본

## 1. 진입점 — 문은 43.201.34.144 하나

- 모든 접속은 엣지 **43.201.34.144**에서 **Tailscale로 홈서버(duradev)** 에 연계된다.
- 구 주소(13.125.131.126 등)·개별 포트 직접 진입은 폐기. 전환 기간의 병행 서빙만 허용.
- 신규 개발은 항상 2단을 함께 고려한다:
  - **1차** — 홈 사이트와 연결 가능하게(경로 통합, `/사이트명/` 방식).
  - **2차** — 원사이트 통합 본(Spring + React)에 흡수 가능하게.
- rpg_game 서비스(8017 자산 워크벤치, 8009 게임 RELAY-47)도 같은 원칙의 전환 대상.
  엣지 경로가 아직 없는 서비스는 실제 상태를 관제에 기록하고 전환을 기다린다 — **없는 경로를
  만들어 안내하지 않는다.**

## 2. 정보 갱신 의무

- 주소 확인: 관제 `http://43.201.34.144/hub` · 정책센터 `http://43.201.34.144/policies` ·
  사칙 정본(notes Git).
- 각 봇은 자기 등록정보(actors.json·roster), 앞으로 보낼 메시지·링크, 이사님 공통지시사항을
  최신으로 유지한다.
- 주소는 하드코딩하지 않고 정책센터·정책 인덱스에서 읽어 쓴다.

## 3. 폴링·스케줄링 점검

- 폴링·스케줄링은 **전부 리스트업**한다: 무엇이 · 어디를 · 몇 분 주기.
- 점검 2항목:
  - **부하** — CPU·요청 수가 무시할 수준인가.
  - **토큰** — 폴링 과정에서 LLM 토큰을 쓰지 않는가. 폴링 자체는 항상 토큰 0이어야 한다.
- 빈 폴링으로 엔진을 깨우지 않는다 — 상태 변화가 있을 때만 보고. 신규 등록 시
  "빈 결과 보고 금지, 상태 변화만 보고" 조건을 필수로 건다.
- 낭비·부하를 발견하면 즉시 조정하고 그 결과를 관제에 기록한다.

## 4. 대화 규칙 (Telegram 운용)

- **큐시작 / 큐끝**: "큐시작" 이후 "큐끝" 전까지는 수신만 한다(중간 응답·중간 요약 금지).
  "큐끝"에서 그동안 내용을 전부 모아 한 번에 답한다.
- **긴 답변 분할**: 파일로 잘려서 나갈 답은 파일 대신 텍스트를 나눠서 말한다.
- **eli5**: 답 끝에 쉬운 말 요약을 붙인다.
- **표 금지**: 텔레그램은 마크다운 표를 못 본다 — 리스트로 풀거나 임시 웹 페이지·이미지로 보여준다.

## 5. 진행 보고 — n/N 확인 게이트

- 일을 시키면 단계를 `1/N` 식으로 번호를 매겨 **각 단계의 변경점**을 보여주고,
  **이사님 확인을 받은 뒤** 다음 단계로 진행한다. 확인 없이 다음 단계로 가지 않는다.
- 예외: 긴급 장애 복구(서비스 다운·데이터 유실 위험)는 먼저 막고 사후 즉시 보고.

## 6. 관제 허브 v1 (봇간 통신)

- 지시·보고·질문은 **8023 `/api/hub/*`** 로 접수한다.
- A봇→B봇 전달: `POST /api/hub/send {from, to, type, payload}`
  - `type=task`만 상대 엔진을 깨운다.
  - `type=notice`(@all 한정)는 활성 공지로 전 봇 문맥에 주입된다(ACK 불필요).
- 표준 폴러 `projects/meeting-room/hub_client.py` — 30초 주기 `drain → ack → done/fail`.
  실패 3회면 못 처리함(DLQ) — 재큐는 이사님 토큰으로만.
- 작업에는 멱등키(`key`)를 붙여 재전송 중복을 막는다.
  상태: 진행=`progress` · 막힘=`blocked` · 완료=`submitted`.
- 현황판: `http://43.201.34.144/hub` (홈 이전 후 동일 경로).
- 폴링 봇 전환은 단계적 — 기존 @멘션 방식과 당분간 병행.

## 7. 상시 답장 규칙 (모든 답장에 포함) — 정본 ORG-RULES §6 미러

- **모델·컨텍스트 사용량 표기**: 모든 답장에 사용 모델명과 컨텍스트 사용량을 붙인다.
  수치는 실측(context-meter 스크립트) 기준이고, 추정 수치를 쓰지 않는다.
- **사용 경로 구분**: LLM Gateway 경유인지 **z.ai API 직접**인지 구분해 표기한다.
  - aws-rpg 기본값: **z.ai API(GLM)** — actors.json `runtime_accounting` = client_surface claude /
    usage_pool z.ai / usage_source runtime_measured_only. 변경되면 등록 원장을 따라 표기를 바꾼다.
- **모델 변경·API 사용 요청 대응**: 요청을 받으면 ①현재 경로·모델 실측값 제시 → ②변경안
  (actors.json providers·runtime_accounting 갱신 + 재기동 절차)을 이사님 확인 후 적용한다.
  임의로 모델·경로를 바꾸지 않는다.
- **숙지한 규칙 정본의 마지막 commit 표기**: 답장에 (1) notes origin/main HEAD, (2) 이 repo
  `PROJECT-RULES.md` 커밋을 붙인다. 갱신 요청 시 `git fetch` 후 재인증한다.
- **관제 주시**: 관제 현황판(`http://43.201.34.144/hub`)과 허브 메시지·공지를 주시한다.
  ※ 선행 조건: 봇별 허브 토큰 발급(현재 미발급 — 발급 전엔 주시 불가, 이를 blocked로 보고).

## 8. rpg 원페이지 이관 계획 (2026-09-08 초안)

담당 페이지의 엣지(:80 하위) 이관 목표 — 프록시 자체는 매니저·관제(codex_dev) 소관,
rpg 쪽은 **경로 확정 + base-path 대응**이 내 몫.

- **게임 웹 (포트 8009)** — `web/`(Flask) + `deploy/rpg-game-8009.service`,
  배포 트리 `/home/ubuntu/apps/rpg-game-01/current`.
  목표: `http://43.201.34.144/rpg/game/` (현 엣지 경로 없음 — 포트 직접 진입은 폐기 원칙)
- **자산 워크벤치 (포트 8017)** — `tools/asset_workbench/`(표준라이브러리 단독 서버).
  목표: `http://43.201.34.144/rpg/workbench/`. 전제: app.py에 base-path(`/rpg/workbench/`)
  대응 수정 + 접속키 유지 + 서비스 재기동(현재 중단 상태).
- **Godot 데모 빌드** — `demo/`(export 산출물) 정적 공개.
  목표: `http://43.201.34.144/rpg/demo/` (선택 — 빌드물 있을 때만)
- **이관 대상 아님**: `projects/rpg-game-01/`(정본), `ideation/` — 페이지가 아니라 Git 정본.
  필요하면 읽기 전용 뷰어만 투영한다.
- **git 전수 확인 (2026-09-08)**: 내 소관 = `rpg_game`(커밋·push 완료, clean) +
  notes 내 티켓 산출물(push 완료). notes의 나머지·scenario·autotrader·approval-board는
  각 소유자(매니저·타 팀장)가 이관 계획을 세운다.

## rpg_game 적용 체크

- 워크벤치·게임 주소 안내는 엣지 경로 기준으로 통일하고, 미프록시 서비스는 현황을 관제에 기록.
- 스케줄 신규 등록은 "빈 결과 보고 금지, 상태 변화만 보고" 조건 필수.
- 공통 사칙 변경은 notes 정본을 먼저 고치고 이 파일을 그에 맞춰 갱신한다(Git 정본 우선).
