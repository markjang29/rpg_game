#!/usr/bin/env python3
"""절차적 SFX 합성기 (표준 라이브러리만 사용).

패링 데모용 효과음 4종을 16-bit PCM mono WAV로 생성한다.
- perfect.wav : 퍼펙트 패링 — 비조화 배음의 금속 클랭 (높고 밝음)
- good.wav    : 일반 패링 — 중간 역할 막는 소리
- hit.wav     : 피격 — 저역 둔탁 노이즈 버스트
- whoosh.wav  : 투사체 발사 — 노이즈 sweep

설계 의도: 손맛의 핵심은 "Perfect 때의 맑은 클랭 + 잔향"이다.
금속성은 배음 비율을 정수배가 아닌(비조화) 것으로 잡아 만든다.
"""
import math
import struct
import wave
import os

SR = 44100  # 샘플레이트


def write_wav(path: str, samples: list[float]) -> None:
    """[-1, 1] float 샘플 리스트 → 16-bit PCM WAV."""
    n = len(samples)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            s = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(s * 32767))
        w.writeframes(bytes(frames))
    print(f"  {os.path.basename(path):14s} {n/SR:5.3f}s  {n} samples")


def env_exp(t: float, decay: float) -> float:
    """지수 감쇠. decay 클수록 빨리 사라짐."""
    return math.exp(-t * decay)


def env_adsr(t: float, dur: float, a: float = 0.001, d: float = 0.05,
             s_level: float = 0.0, r: float = 0.05) -> float:
    """간단한 ADSR. sustain 레벨 0이면 attack-decay 폭발형."""
    if t < a:
        return t / a if a > 0 else 1.0
    if t < a + d:
        return 1.0 - (1.0 - s_level) * ((t - a) / d)
    rel_start = dur - r
    if t < rel_start:
        return s_level
    if t < dur:
        return s_level * (1.0 - (t - rel_start) / r) if r > 0 else 0.0
    return 0.0


def synth_perfect() -> list[float]:
    """비조화 배음 금속 클랭. 밝고 맑게, 약간의 잔향."""
    dur = 0.55
    base = 1320.0  # E6 근처 — 밝은 클랭
    # 비조화 배음 비율 (금속 성질: 정수배 X)
    partials = [(1.0, 1.00, 9.0), (2.76, 0.55, 11.0),
                (5.40, 0.30, 14.0), (8.93, 0.18, 18.0)]
    n = int(dur * SR)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        e = env_exp(t, 7.5)
        s = 0.0
        for ratio, amp, dec in partials:
            s += amp * math.sin(2 * math.pi * base * ratio * t) * env_exp(t, dec)
        out[i] = s * e * 0.5
    # 잔향: 작은 딜레이 echo
    delay = int(0.045 * SR)
    for i in range(delay, n):
        out[i] += out[i - delay] * 0.22
    return out


def synth_good() -> list[float]:
    """중간 패막 — triangle 파, 따뜻한 톤."""
    dur = 0.22
    base = 540.0
    n = int(dur * SR)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        e = env_exp(t, 16.0)
        ph = 2 * math.pi * base * t
        # triangle 근사 (기본 + 3배음)
        tri = math.sin(ph) + 0.12 * math.sin(3 * ph)
        # 살짝 노이즈로 "막은" 질감
        noise = _pseudo_noise(i) * 0.08
        out[i] = (tri * e + noise * e) * 0.55
    return out


def synth_hit() -> list[float]:
    """피격 — 저역 둔탁. 노이즈 + 저주파 thud."""
    dur = 0.32
    n = int(dur * SR)
    out = [0.0] * n
    # 1-pole 로우패스 상태
    prev = 0.0
    alpha = 0.18  # 컷오프 낮춤
    for i in range(n):
        t = i / SR
        e = env_exp(t, 9.0)
        noise = _pseudo_noise(i)
        filt = prev + alpha * (noise - prev)
        prev = filt
        thud = math.sin(2 * math.pi * 95.0 * t) * env_exp(t, 13.0)
        out[i] = (filt * 0.9 + thud * 0.7) * e * 0.7
    return out


def synth_whoosh() -> list[float]:
    """투사체 발사 — 노이즈 band-sweep. 짧고 가벼움."""
    dur = 0.18
    n = int(dur * SR)
    out = [0.0] * n
    prev = 0.0
    for i in range(n):
        t = i / SR
        prog = t / dur
        # 주파수 올라갔다 내려옴
        alpha = 0.05 + 0.5 * math.sin(math.pi * prog)
        noise = _pseudo_noise(i + 7777)
        prev = prev + alpha * (noise - prev)
        e = math.sin(math.pi * prog)  # 올라갔다 내려옴
        out[i] = prev * e * 0.4
    return out


_noise_state = {"x": 2463534242}


def _pseudo_noise(i: int) -> float:
    """결정적 의사난수 [-1,1]. numpy 없이 노이즈 합성용."""
    x = _noise_state["x"] ^ (i * 2654435761)
    x = (x ^ (x >> 13)) * 1274126177 & 0xFFFFFFFF
    x ^= x >> 16
    return (x / 0x7FFFFFFF) - 1.0


def main() -> None:
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    print(f"Generating SFX -> {out_dir}")
    sounds = {
        "perfect.wav": synth_perfect(),
        "good.wav": synth_good(),
        "hit.wav": synth_hit(),
        "whoosh.wav": synth_whoosh(),
    }
    for name, samples in sounds.items():
        write_wav(os.path.join(out_dir, name), samples)
    print("done.")


if __name__ == "__main__":
    main()
