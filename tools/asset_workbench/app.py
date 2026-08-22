#!/usr/bin/env python3
"""RPG 게임 자산 워크벤치 — 프로토타입 스파이크 (RELAY-36).

의존성 없음(파이썬 표준 라이브러리만). NAI(Opus 무료 조건) 이미지 생성 +
자산 분류·리롤·메타 정본·갤러리. 정식 구현 여부는 relay 4-설계검토에서 결정.

기동: RELAY_TICKET=RELAY-36 RPG_WB_KEY=<접속키> python3 app.py --port 8016
"""
import io
import json
import os
import random
import sys
import time
import urllib.request
import urllib.error
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = 8016
if "--port" in sys.argv:
    PORT = int(sys.argv[sys.argv.index("--port") + 1])
RELAY_TICKET = os.environ.get("RELAY_TICKET", "RELAY-36")
ACCESS_KEY = os.environ.get("RPG_WB_KEY", "")

ROOT = Path(__file__).parent
STORE = ROOT / "store"
STORE.mkdir(exist_ok=True)
INDEX = ROOT / "index.html"
NAI_TOKEN_PATH = Path.home() / ".nai-token"
NAI_HOST = "https://image.novelai.net/ai/generate-image"
MODEL = "nai-diffusion-4-5-full"

# ── 자산 유형 정의 (프롬프트 템플릿) ─────────────────────────────
TYPES = {
    "CHR": {
        "label": "캐릭터",
        "size": (832, 1216),
        "base": ("masterpiece, best quality, very aesthetic, character design, single character, "
                 "full body, dynamic pose, detailed costume, clean silhouette, simple background, "
                 "game character concept art"),
        "neg": "multiple people, text, logo, watermark",
    },
    "WLD": {
        "label": "월드/배경",
        "size": (832, 1216),
        "base": ("masterpiece, best quality, very aesthetic, environment concept art, "
                 "breathtaking scenery, atmospheric perspective, depth, no humans, "
                 "game background art"),
        "neg": "human, people, text, logo, watermark",
    },
    "WPN": {
        "label": "무기·장비",
        "size": (832, 1216),
        "base": ("masterpiece, best quality, very aesthetic, weapon concept art, single weapon, "
                 "centered composition, floating display, dark gradient background, "
                 "intricate details, game asset design sheet"),
        "neg": "human, hands, multiple weapons, text, logo, watermark",
    },
    "ITM": {
        "label": "아이템·오브",
        "size": (1024, 1024),
        "base": ("masterpiece, best quality, very aesthetic, game item concept art, single item, "
                 "centered, glowing, magic particles, dark background, item icon design"),
        "neg": "human, hands, text, logo, watermark",
    },
    "UI": {
        "label": "UI 요소",
        "size": (1024, 1024),
        "base": ("masterpiece, best quality, very aesthetic, game UI design element, "
                 "clean minimal, centered, dark background, mobile game interface asset"),
        "neg": "human, cluttered, text, letters, logo, watermark",
    },
    "EFX": {
        "label": "이펙트(VFX)",
        "size": (1024, 1024),
        "base": ("masterpiece, best quality, very aesthetic, game VFX concept art, single skill effect, "
                 "energy burst, glowing slash trail, particle effects, dark background, "
                 "skill effect design sheet, RPG combat special effect"),
        "neg": "human, character, face, text, logo, watermark, cluttered",
    },
}

STYLES = {
    "illust": {"label": "일러스트", "suffix": "digital illustration, vivid colors, sharp focus"},
    "dot": {"label": "도트(픽셀)", "suffix": "pixel art, 16-bit retro game style, crisp pixels, limited palette"},
    "paint": {"label": "핸드페인팅", "suffix": "hand-painted, gouache texture, soft brush strokes"},
}

BASE_NEG = ("lowres, artistic error, film grain, scan artifacts, worst quality, low quality, "
            "jpeg artifacts, blurry, signature")


# ── NAI 생성 (오푸스 무료 조건 고정: ≤1MP·28스텝·1장) ─────────────
def nai_generate(prompt: str, negative: str, w: int, h: int, seed: int) -> bytes:
    token = NAI_TOKEN_PATH.read_text().strip()
    body = {
        "input": prompt,
        "model": MODEL,
        "action": "generate",
        "parameters": {
            "params_version": 3, "width": w, "height": h, "scale": 5,
            "sampler": "k_euler_ancestral", "steps": 28, "n_samples": 1,
            "ucPreset": 0, "qualityToggle": True,
            "negative_prompt": negative, "seed": seed, "characterPrompts": [],
            "v4_prompt": {"caption": {"base_caption": prompt, "char_captions": []},
                          "use_coords": False, "use_order": True},
            "v4_negative_prompt": {"caption": {"base_caption": negative, "char_captions": []}},
        },
    }
    req = urllib.request.Request(NAI_HOST, data=json.dumps(body).encode(), method="POST",
        headers={"Authorization": "Bearer " + token, "Content-Type": "application/json",
                 "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=240) as r:
        data = r.read()
    zf = zipfile.ZipFile(io.BytesIO(data))
    return zf.read(zf.namelist()[0])


# ── 자장 관리 ─────────────────────────────────────────────
def next_id(tcode: str) -> str:
    nums = [0]
    for f in STORE.glob(f"WB-{tcode}-*.json"):
        try:
            nums.append(int(f.stem.split("-")[-1]))
        except ValueError:
            pass
    return f"WB-{tcode}-{max(nums) + 1:03d}"


def save_asset(tcode: str, style: str, extra: str, prompt: str, negative: str,
               seed: int, parent: str | None) -> dict:
    w, h = TYPES[tcode]["size"]
    png = nai_generate(prompt, negative, w, h, seed)
    aid = next_id(tcode)
    (STORE / f"{aid}.png").write_bytes(png)
    meta = {
        "id": aid, "type": tcode, "type_label": TYPES[tcode]["label"],
        "style": style, "extra": extra.strip(),
        "prompt": prompt, "negative": negative, "model": MODEL,
        "seed": seed, "steps": 28, "scale": 5, "size": f"{w}x{h}",
        "ts": time.strftime("%Y-%m-%d %H:%M:%S"), "parent": parent,
        "status": "초안",
    }
    (STORE / f"{aid}.json").write_text(json.dumps(meta, ensure_ascii=False, indent=1))
    return meta


def gallery(limit: int = 60) -> list:
    metas = []
    for f in STORE.glob("WB-*.json"):
        try:
            metas.append(json.loads(f.read_text()))
        except Exception:
            pass
    metas.sort(key=lambda m: m["ts"], reverse=True)
    return metas[:limit]


# ── HTTP 핸들러 ───────────────────────────────────────────
class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[%s] %s\n" % (time.strftime("%H:%M:%S"), fmt % args))

    def authorized(self) -> bool:
        if not ACCESS_KEY:
            return True  # 키 미설정 시 오픈(로컬 테스트용)
        key = None
        if "k=" in (self.path or ""):
            from urllib.parse import urlparse, parse_qs
            key = (parse_qs(urlparse(self.path).query).get("k") or [None])[0]
        if not key:
            key = self.headers.get("X-Key")
        return key == ACCESS_KEY

    def _send(self, code: int, body: bytes, ctype: str = "application/json; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code: int, obj):
        self._send(code, json.dumps(obj, ensure_ascii=False).encode())

    def do_GET(self):
        if not self.authorized():
            self._json(403, {"error": "키가 올바르지 않습니다. URL에 ?k=<키>를 붙이세요."})
            return
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            self._send(200, INDEX.read_bytes(), "text/html; charset=utf-8")
        elif path == "/api/types":
            self._json(200, {"types": {k: {"label": v["label"]} for k, v in TYPES.items()},
                             "styles": {k: {"label": v["label"]} for k, v in STYLES.items()}})
        elif path == "/api/gallery":
            self._json(200, {"items": gallery()})
        elif path.startswith("/img/"):
            fid = path[5:].replace("/", "")
            f = STORE / fid
            if f.suffix == ".png" and f.exists():
                self._send(200, f.read_bytes(), "image/png")
            else:
                self._json(404, {"error": "not found"})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        if not self.authorized():
            self._json(403, {"error": "unauthorized"})
            return
        length = int(self.headers.get("Content-Length") or 0)
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self._json(400, {"error": "bad json"})
            return
        path = self.path.split("?")[0]
        try:
            if path == "/api/generate":
                tcode = body.get("type", "CHR")
                if tcode not in TYPES:
                    self._json(400, {"error": f"알 수 없는 유형 {tcode}"})
                    return
                style = body.get("style", "illust")
                if style not in STYLES:
                    style = "illust"
                extra = str(body.get("extra", ""))[:500]
                seed = int(body.get("seed") or random.randint(0, 2**31 - 1)) % (2**31)
                prompt = ", ".join(x for x in [TYPES[tcode]["base"], extra,
                                               STYLES[style]["suffix"]] if x)
                negative = BASE_NEG + ", " + TYPES[tcode]["neg"]
                meta = save_asset(tcode, style, extra, prompt, negative, seed, None)
                self._json(200, meta)
            elif path == "/api/reroll":
                src = body.get("id", "")
                f = STORE / f"{src}.json"
                if not f.exists():
                    self._json(404, {"error": "자산 없음"})
                    return
                m = json.loads(f.read_text())
                seed = random.randint(0, 2**31 - 1)
                meta = save_asset(m["type"], m["style"], m.get("extra", ""),
                                  m["prompt"], m["negative"], seed, src)
                self._json(200, meta)
            else:
                self._json(404, {"error": "not found"})
        except urllib.error.HTTPError as e:
            self._json(502, {"error": f"NAI 오류 HTTP {e.code}"})
        except Exception as e:
            self._json(500, {"error": str(e)})


def main():
    srv = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"asset workbench up :{PORT} ticket={RELAY_TICKET} store={STORE}")
    srv.serve_forever()


if __name__ == "__main__":
    main()
