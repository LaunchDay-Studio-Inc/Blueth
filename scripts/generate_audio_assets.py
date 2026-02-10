#!/usr/bin/env python3
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "audio")
os.makedirs(OUT_DIR, exist_ok=True)

SR = 44100


def clamp(v: float) -> float:
    if v < -1.0:
        return -1.0
    if v > 1.0:
        return 1.0
    return v


def write_wav(path: str, samples):
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        frames = bytearray()
        for s in samples:
            frames += struct.pack("<h", int(clamp(s) * 32767.0))
        wf.writeframes(frames)


def env_adsr(t: float, dur: float, a: float, d: float, s: float, r: float) -> float:
    if t < a:
        return t / max(1e-6, a)
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / max(1e-6, d))
    if t < dur - r:
        return s
    if t < dur:
        return s * (1.0 - (t - (dur - r)) / max(1e-6, r))
    return 0.0


def make_music_loop():
    dur = 24.0
    frames = int(SR * dur)
    notes = [220.0, 261.63, 293.66, 329.63, 392.0, 440.0]
    bass = [55.0, 65.41, 73.42, 82.41, 98.0, 110.0]
    seq_len = 0.5
    out = []
    for i in range(frames):
        t = i / SR
        step = int(t / seq_len) % len(notes)
        n = notes[step]
        b = bass[step]
        ph1 = math.sin(2.0 * math.pi * n * t)
        ph2 = math.sin(2.0 * math.pi * (n * 0.5) * t + 0.2)
        ph3 = math.sin(2.0 * math.pi * (b) * t)
        pulse = 1.0 if math.sin(2.0 * math.pi * 2.0 * t) > 0 else -1.0
        wobble = math.sin(2.0 * math.pi * 0.25 * t)
        mix = (ph1 * 0.22 + ph2 * 0.15 + ph3 * 0.26 + pulse * 0.05) * (0.82 + wobble * 0.12)
        # soft transient every beat
        beat_pos = (t % seq_len) / seq_len
        if beat_pos < 0.08:
            mix += math.sin(2.0 * math.pi * 1300.0 * t) * (0.08 * (1.0 - beat_pos / 0.08))
        out.append(mix * 0.58)
    write_wav(os.path.join(OUT_DIR, "music_loop.wav"), out)


def make_shotgun():
    dur = 0.13
    frames = int(SR * dur)
    out = []
    seed = random.Random(1)
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.002, 0.04, 0.15, 0.06)
        noise = (seed.random() * 2.0 - 1.0)
        tone = math.sin(2.0 * math.pi * 180.0 * t)
        out.append((noise * 0.65 + tone * 0.25) * e * 0.9)
    write_wav(os.path.join(OUT_DIR, "sfx_shotgun.wav"), out)


def make_beam():
    dur = 0.18
    frames = int(SR * dur)
    out = []
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.004, 0.02, 0.55, 0.07)
        c = 780.0 + 420.0 * (t / dur)
        tone = math.sin(2.0 * math.pi * c * t)
        shimmer = math.sin(2.0 * math.pi * (c * 2.01) * t)
        out.append((tone * 0.55 + shimmer * 0.2) * e * 0.8)
    write_wav(os.path.join(OUT_DIR, "sfx_beam.wav"), out)


def make_boomerang():
    dur = 0.22
    frames = int(SR * dur)
    out = []
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.006, 0.03, 0.38, 0.08)
        f = 360.0 + 220.0 * math.sin(2.0 * math.pi * 6.0 * t)
        tone = math.sin(2.0 * math.pi * f * t)
        out.append(tone * e * 0.72)
    write_wav(os.path.join(OUT_DIR, "sfx_boomerang.wav"), out)


def make_surge():
    dur = 0.26
    frames = int(SR * dur)
    out = []
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.008, 0.05, 0.45, 0.12)
        sweep = 180.0 + 1300.0 * (t / dur)
        tone = math.sin(2.0 * math.pi * sweep * t)
        out.append(tone * e * 0.78)
    write_wav(os.path.join(OUT_DIR, "sfx_surge.wav"), out)


def make_hit():
    dur = 0.08
    frames = int(SR * dur)
    out = []
    seed = random.Random(2)
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.001, 0.02, 0.08, 0.03)
        noise = (seed.random() * 2.0 - 1.0)
        out.append(noise * e * 0.55)
    write_wav(os.path.join(OUT_DIR, "sfx_hit.wav"), out)


def make_levelup():
    dur = 0.32
    frames = int(SR * dur)
    out = []
    chord = [523.25, 659.25, 783.99]
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.004, 0.06, 0.6, 0.14)
        mix = 0.0
        for idx, f in enumerate(chord):
            mix += math.sin(2.0 * math.pi * f * t + idx * 0.2) * (0.22 - idx * 0.03)
        out.append(mix * e * 0.9)
    write_wav(os.path.join(OUT_DIR, "sfx_levelup.wav"), out)


def make_death():
    dur = 0.45
    frames = int(SR * dur)
    out = []
    for i in range(frames):
        t = i / SR
        e = env_adsr(t, dur, 0.006, 0.10, 0.38, 0.20)
        freq = 320.0 - 250.0 * (t / dur)
        tone = math.sin(2.0 * math.pi * max(50.0, freq) * t)
        out.append(tone * e * 0.9)
    write_wav(os.path.join(OUT_DIR, "sfx_death.wav"), out)


def main():
    make_music_loop()
    make_shotgun()
    make_beam()
    make_boomerang()
    make_surge()
    make_hit()
    make_levelup()
    make_death()
    print("generated", OUT_DIR)


if __name__ == "__main__":
    main()
