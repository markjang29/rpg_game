---
name: sprite-atlas-local
description: >
  로컬 전용 스프라이트 파이프라인 — 시트 슬라이스·크로마킷 알파 추출·아틀라스 PNG+manifest.json 합성.
  asset workbench 스토어(CHR/WLD/WPN/ITM/FX/UIX)로 넣을 스프라이트 시트를 다룰 때 사용.
  외부 이미지젠 API는 일절 호출하지 않는다(입력은 항상 로컬에 있는 기존 이미지).
---

# sprite-atlas-local (로컬 파이프라인 전용)

aldegad/sprite-gen(Apache-2.0)의 결정론적 로컬 스테이지만 벤더한 스킬.
업스트림의 gen(이미지젠 API)·audio(ElevenLabs)·video(외부 다운로드) 스테이지는 미포함 —
이사님 10-27 경계(외부 API·자격증명 미사용) 준수.

## 절대 금지

- 외부 API 호출·자격증명·과금 — 어떤 사유로도 하지 않는다.
- 벤더 코드 수정(보안 검수된 스냅샷 그대로 사용). 필요하면 별도 검수 후 재반영.

## 워크플로 (입력: 로컬에 있는 스프라이트 시트 PNG)

1. **슬라이스+크로마 알파**: `vendor/scripts/slice_sheet_cells.py --sheet 시트.png --out-dir 셀디렉토리/ --chroma-key "#배경색" --grid COLSxROWS [--names a,b,c,...]`
2. **run-dir 생성**: `vendor/scripts/unpack_atlas_run.py --pngs-dir 셀디렉토리/ --state-name 상태명 --out-dir 런디렉토리/`
3. **아틀라스 굽기**: `vendor/scripts/compose_sprite_atlas.py --run-dir 런디렉토리/`
   → `sprite-sheet-alpha.png` + `manifest.json`(프레임 좌표·셀 규격)
4. 산출을 asset workbench 스토어 형식(CHR/WLD/WPN/ITM/FX/UIX)으로 이관할 때는 manifest 좌표를 그대로 쓴다.

실행 환경: `.python/`(venv, Pillow+NumPy). 재구성: `python3 -m venv .python && .python/bin/pip install "pillow>=10,<14" "numpy>=2,<3"`.

## 검수 근거

- 벤더 범위: 21모듈 의존 폐쇄 분석(AST 기반) — 금지 영역(gen/audio/video) 0포함 확인.
- 상세: repo root `SKILL-FUSION-2026-10-27.md`, 원장 notes `016f4cb`.
