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

@app.route('/static/<path:filename>')
def static_files(filename):
    """정적 파일 제공"""
    return send_from_directory('static', filename)

if __name__ == '__main__':
    print("RPG 시스템 설명 서버 시작: http://0.0.0.0:8004")
    print("내용 수정 시 web/content/ 디렉토리의 마크다운 파일을 수정하세요")
    app.run(host='0.0.0.0', port=8004, debug=True)
