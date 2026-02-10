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


def softclip(v: float) -> float:
    return math.tanh(v * 1.7) / math.tanh(1.7)


def write_wav(path: str, samples):
    with wave.open(path, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        frames = bytearray()
        for l, r in samples:
            frames += struct.pack("<h", int(clamp(l) * 32767.0))
            frames += struct.pack("<h", int(clamp(r) * 32767.0))
        wf.writeframes(frames)


def env_adsr(t: float, dur: float, a: float, d: float, s: float, r: float) -> float:
    if t < 0.0:
        return 0.0
    if t < a:
        return t / max(1e-6, a)
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / max(1e-6, d))
    if t < dur - r:
        return s
    if t < dur:
        return s * (1.0 - (t - (dur - r)) / max(1e-6, r))
    return 0.0


def exp_env(t: float, dur: float, power: float = 2.0) -> float:
    if t < 0.0 or t >= dur:
        return 0.0
    return max(0.0, 1.0 - t / dur) ** power


def pan_sample(v: float, pan: float):
    pan = max(-1.0, min(1.0, pan))
    left = v * math.sqrt((1.0 - pan) * 0.5)
    right = v * math.sqrt((1.0 + pan) * 0.5)
    return left, right


def mono_to_stereo(mono, width: float = 0.0, lfo_hz: float = 0.0):
    out = []
    for i, v in enumerate(mono):
        pan = 0.0
        if lfo_hz > 0.0 and width > 0.0:
            pan = math.sin(2.0 * math.pi * lfo_hz * (i / SR)) * width
        out.append(pan_sample(v, pan))
    return out


def apply_delay_stereo(samples, delay_seconds: float, feedback: float, mix: float):
    delay_n = max(1, int(delay_seconds * SR))
    out = [(0.0, 0.0)] * len(samples)
    for i in range(len(samples)):
        in_l, in_r = samples[i]
        prev_l = out[i - delay_n][0] if i >= delay_n else 0.0
        prev_r = out[i - delay_n][1] if i >= delay_n else 0.0
        wet_l = prev_l * feedback
        wet_r = prev_r * feedback
        out_l = in_l * (1.0 - mix) + (in_l + wet_l) * mix
        out_r = in_r * (1.0 - mix) + (in_r + wet_r) * mix
        out[i] = (out_l, out_r)
    return out


def normalize_stereo(samples, peak: float = 0.92):
    max_val = 1e-6
    for l, r in samples:
        max_val = max(max_val, abs(l), abs(r))
    scale = peak / max_val
    return [(softclip(l * scale), softclip(r * scale)) for (l, r) in samples]


def make_music_loop():
    dur = 32.0
    frames = int(SR * dur)
    out = []

    progression = [
        (55.0, 69.3, 82.41, 98.0),
        (61.74, 77.78, 92.5, 110.0),
        (49.0, 61.74, 73.42, 92.5),
        (65.41, 82.41, 98.0, 117.0),
    ]

    for i in range(frames):
        t = i / SR
        bar = int(t / 4.0) % len(progression)
        root, third, fifth, seventh = progression[bar]

        beat = t % 0.5
        kick = 0.0
        if beat < 0.13:
            env = exp_env(beat, 0.13, 2.8)
            freq = 148.0 - 102.0 * (beat / 0.13)
            kick = math.sin(2.0 * math.pi * max(42.0, freq) * t) * env * 0.66

        snare_phase = (t + 0.25) % 1.0
        snare = 0.0
        if snare_phase < 0.16:
            env = exp_env(snare_phase, 0.16, 2.1)
            noise = random.uniform(-1.0, 1.0)
            tone = math.sin(2.0 * math.pi * 214.0 * t)
            snare = (noise * 0.74 + tone * 0.20) * env * 0.38

        hat_phase = t % 0.25
        hat = 0.0
        if hat_phase < 0.042:
            env = exp_env(hat_phase, 0.042, 1.3)
            noise = random.uniform(-1.0, 1.0)
            hat = noise * env * 0.16

        bass = (
            math.sin(2.0 * math.pi * root * t)
            + 0.42 * math.sin(2.0 * math.pi * root * 2.0 * t + 0.18)
        ) * 0.24

        pad = (
            math.sin(2.0 * math.pi * (third * 0.5) * t + 0.1)
            + math.sin(2.0 * math.pi * (fifth * 0.5) * t + 1.2)
            + math.sin(2.0 * math.pi * (seventh * 0.5) * t + 2.1)
        ) * 0.09

        arp_step = int(t / 0.125) % 8
        arp_freqs = [root * 2.0, third * 2.0, fifth * 2.0, seventh * 2.0, fifth * 2.0, third * 2.0, root * 2.0, third * 2.0]
        arp_freq = arp_freqs[arp_step]
        arp_local = t % 0.125
        arp_env = exp_env(arp_local, 0.125, 1.6)
        arp = (
            math.sin(2.0 * math.pi * arp_freq * t)
            + 0.28 * math.sin(2.0 * math.pi * arp_freq * 2.0 * t)
        ) * arp_env * 0.17

        swirl = 0.018 * math.sin(2.0 * math.pi * 0.10 * t)
        core = bass + pad + arp + kick + snare + hat
        left = core + arp * (0.22 + 0.18 * math.sin(2.0 * math.pi * 0.27 * t)) + swirl
        right = core + arp * (-0.22 + 0.18 * math.cos(2.0 * math.pi * 0.29 * t)) - swirl
        out.append((left, right))

    out = apply_delay_stereo(out, delay_seconds=0.22, feedback=0.32, mix=0.34)
    out = normalize_stereo(out, peak=0.90)
    write_wav(os.path.join(OUT_DIR, "music_loop.wav"), out)


def make_shotgun():
    dur = 0.20
    frames = int(SR * dur)
    mono = []
    seed = random.Random(11)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.002, 0.04, 0.16, 0.09)
        noise = seed.uniform(-1.0, 1.0)
        boom_freq = 140.0 - 85.0 * (t / dur)
        boom = math.sin(2.0 * math.pi * max(44.0, boom_freq) * t)
        crack = math.sin(2.0 * math.pi * 1800.0 * t) * exp_env(t, 0.03, 2.0)
        mono.append((noise * 0.70 + boom * 0.42 + crack * 0.16) * env)

    out = mono_to_stereo(mono, width=0.22, lfo_hz=6.0)
    out = apply_delay_stereo(out, delay_seconds=0.05, feedback=0.18, mix=0.18)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_shotgun.wav"), out)


def make_beam():
    dur = 0.24
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.004, 0.03, 0.62, 0.08)
        c = 620.0 + 820.0 * (t / dur)
        tone = math.sin(2.0 * math.pi * c * t)
        shimmer = math.sin(2.0 * math.pi * c * 1.997 * t + 0.9)
        air = math.sin(2.0 * math.pi * 28.0 * t)
        mono.append((tone * 0.56 + shimmer * 0.23 + air * 0.08) * env)

    out = mono_to_stereo(mono, width=0.38, lfo_hz=9.0)
    out = apply_delay_stereo(out, delay_seconds=0.06, feedback=0.28, mix=0.24)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_beam.wav"), out)


def make_boomerang():
    dur = 0.28
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.005, 0.04, 0.44, 0.10)
        wob = math.sin(2.0 * math.pi * 7.0 * t)
        f = 330.0 + 190.0 * wob
        tone = math.sin(2.0 * math.pi * f * t)
        whoosh = math.sin(2.0 * math.pi * 940.0 * t) * exp_env(t, 0.07, 2.3)
        mono.append((tone * 0.62 + whoosh * 0.14) * env)

    out = mono_to_stereo(mono, width=0.44, lfo_hz=5.2)
    out = apply_delay_stereo(out, delay_seconds=0.08, feedback=0.22, mix=0.22)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_boomerang.wav"), out)


def make_surge():
    dur = 0.34
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.006, 0.06, 0.55, 0.14)
        sweep = 140.0 + 1550.0 * (t / dur)
        tone = math.sin(2.0 * math.pi * sweep * t)
        sub = math.sin(2.0 * math.pi * 72.0 * t)
        sparkle = math.sin(2.0 * math.pi * 2100.0 * t) * exp_env(t, 0.05, 2.0)
        mono.append((tone * 0.58 + sub * 0.30 + sparkle * 0.09) * env)

    out = mono_to_stereo(mono, width=0.50, lfo_hz=4.8)
    out = apply_delay_stereo(out, delay_seconds=0.09, feedback=0.36, mix=0.30)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_surge.wav"), out)


def make_hit():
    dur = 0.10
    frames = int(SR * dur)
    mono = []
    seed = random.Random(23)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.018, 0.10, 0.04)
        noise = seed.uniform(-1.0, 1.0)
        click = math.sin(2.0 * math.pi * 2700.0 * t) * exp_env(t, 0.02, 2.5)
        mono.append((noise * 0.64 + click * 0.22) * env)

    out = mono_to_stereo(mono, width=0.16, lfo_hz=12.0)
    out = normalize_stereo(out, peak=0.80)
    write_wav(os.path.join(OUT_DIR, "sfx_hit.wav"), out)


def make_levelup():
    dur = 0.42
    frames = int(SR * dur)
    mono = []
    chord = [523.25, 659.25, 783.99, 1046.5]
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.006, 0.08, 0.70, 0.16)
        mix = 0.0
        for idx, f in enumerate(chord):
            mix += math.sin(2.0 * math.pi * f * t + idx * 0.4) * (0.22 - idx * 0.03)
        sparkle = math.sin(2.0 * math.pi * 1900.0 * t) * exp_env(t, 0.09, 2.0)
        mono.append((mix + sparkle * 0.15) * env)

    out = mono_to_stereo(mono, width=0.34, lfo_hz=3.4)
    out = apply_delay_stereo(out, delay_seconds=0.12, feedback=0.34, mix=0.35)
    out = normalize_stereo(out, peak=0.90)
    write_wav(os.path.join(OUT_DIR, "sfx_levelup.wav"), out)


def make_death():
    dur = 0.52
    frames = int(SR * dur)
    mono = []
    seed = random.Random(37)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.008, 0.12, 0.40, 0.24)
        freq = 320.0 - 250.0 * (t / dur)
        tone = math.sin(2.0 * math.pi * max(50.0, freq) * t)
        noise = seed.uniform(-1.0, 1.0) * exp_env(t, dur, 1.4)
        mono.append((tone * 0.68 + noise * 0.20) * env)

    out = mono_to_stereo(mono, width=0.28, lfo_hz=2.4)
    out = apply_delay_stereo(out, delay_seconds=0.10, feedback=0.24, mix=0.20)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_death.wav"), out)


def main():
    random.seed(1234)
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
