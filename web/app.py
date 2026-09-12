#!/usr/bin/env python3
"""
RPG 시스템 설명 웹서버
8004 포트에서 실행
정책 변경 시 content/ 디렉토리의 마크다운 파일만 수정하면 반영됨
"""

from flask import Flask, render_template, send_from_directory
import markdown
import os
from pathlib import Path

app = Flask(__name__)

CONTENT_DIR = Path(__file__).parent / "content"
GODOT_TACTICS_DIR = Path(__file__).parent / "static" / "godot-tactics"

def load_markdown_content(filename):
    """마크다운 파일을 읽어서 HTML로 변환"""
    filepath = CONTENT_DIR / filename
    if not filepath.exists():
        return f"<p class='error'>내용 파일을 찾을 수 없습니다: {filename}</p>"

    with open(filepath, 'r', encoding='utf-8') as f:
        md_content = f.read()

    return markdown.markdown(md_content, extensions=['fenced_code', 'tables', 'nl2br'])

@app.route('/')
def index():
    """메인 페이지"""
    # 섹션별 마크다운 파일 로드
    sections = {
        'hero': load_markdown_content('hero.md'),
        'core': load_markdown_content('core.md'),
        'combat': load_markdown_content('combat.md'),
        'modules': load_markdown_content('modules.md'),
    }
    return render_template('index.html', sections=sections)

@app.route('/prototype')
def prototype():
    """관찰·추론·회피 전투의 플레이 가능한 웹 프로토타입."""
    return render_template('prototype.html')

@app.route('/prototype/tactics')
def tactics_prototype():
    """파랜드풍 등각 전술 전투 체감 프로토타입."""
    return render_template('tactics.html')

@app.route('/prototype/godot-tactics/')
def godot_tactics_prototype():
    """Godot Web Export 전술 전투 프로토타입."""
    return send_from_directory(GODOT_TACTICS_DIR, 'index.html')

@app.route('/prototype/godot-tactics/<path:filename>')
def godot_tactics_files(filename):
    """Godot Web Export의 WASM/PCK/JS 파일 제공."""
    return send_from_directory(GODOT_TACTICS_DIR, filename)

@app.route('/static/<path:filename>')
def static_files(filename):
    """정적 파일 제공"""
    return send_from_directory('static', filename)


# ── 매트릭스 오브젝트 ID·기술 표기 (이사님 09-12 지시: 오브젝트마다 구현기술·고유ID) ──
# 8018의 _debug_ids 선례: 응답이 HTML이면 주요 오브젝트(section/카드/버튼/표)에
# data-obj-id(고유ID)·data-impl(구현기술)을 서버사이드로 부여한다. ?debug=0으로 끈다.
SITE_ID = "8009"
SITE_IMPL = "Flask/Gunicorn · Python · HTML/JS"


@app.after_request
def _tag_object_ids(resp):
    if resp.mimetype != "text/html":
        return resp
    from flask import request
    if request.args.get("debug") == "0":
        return resp
    import re as _re
    body = resp.get_data(as_text=True)
    if not body:
        return resp

    counter = {"n": 0}

    def _tag(match):
        counter["n"] += 1
        tag, attrs = match.group(1), match.group(2)
        if "data-obj-id" in attrs:
            return match.group(0)
        oid = f"8009-{tag}-{counter['n']:03d}"
        return f"<{tag} data-obj-id=\"{oid}\" data-impl=\"{SITE_ID}:{SITE_IMPL}\"{attrs}>"

    # h2/h3(섹션 제목)·button·table·.card류 div에 우선 부여 — 과다 태깅 방지
    tagged = _re.sub(r"<(h2|h3|button|table|details)([^>]*)>", _tag, body)
    # h2/h3가 있으면 그 부모 section까지 식별 가능하도록 id 없는 section에도 태깅
    tagged = _re.sub(r"(<section)((?![^>]*\bid=)[^>]*)>",
                     lambda m: f"{m.group(1)} data-obj-id=\"8009-sec-{len(m.group(2))%999:03d}\" data-impl=\"{SITE_ID}:{SITE_IMPL}\"{m.group(2)}>",
                     tagged)
    # 메타(구현기술·고유ID)가 없는 head를 보강 (엣지 경유 응답 대비)
    if 'name="site-id"' not in tagged:
        tagged = tagged.replace(
            "<head>",
            f'<head><meta name="site-id" content="{SITE_ID}">'
            f'<meta name="implemented-with" content="{SITE_IMPL}">', 1)
    resp.set_data(tagged)
    return resp


if __name__ == '__main__':
    print("RPG 시스템 설명 서버 시작: http://0.0.0.0:8004")
    print("내용 수정 시 web/content/ 디렉토리의 마크다운 파일을 수정하세요")
    app.run(host='0.0.0.0', port=8004, debug=True)
