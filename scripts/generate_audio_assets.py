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


def make_music_loop(path: str, mood: str):
    dur = 32.0
    frames = int(SR * dur)
    out = []

    if mood == "frost":
        progression = [
            (55.0, 65.41, 82.41, 98.0),
            (49.0, 61.74, 73.42, 92.5),
            (46.25, 58.27, 69.30, 87.31),
            (61.74, 73.42, 92.50, 110.0),
        ]
        kick_gain = 0.40
        snare_gain = 0.26
        hat_gain = 0.10
        pad_gain = 0.12
        arp_gain = 0.13
        bass_gain = 0.20
        delay_mix = 0.40
    elif mood == "umbra":
        progression = [
            (46.25, 55.0, 69.30, 82.41),
            (41.20, 51.91, 61.74, 77.78),
            (43.65, 55.0, 65.41, 82.41),
            (38.89, 49.0, 58.27, 73.42),
        ]
        kick_gain = 0.62
        snare_gain = 0.42
        hat_gain = 0.14
        pad_gain = 0.08
        arp_gain = 0.16
        bass_gain = 0.28
        delay_mix = 0.28
    elif mood == "endless":
        progression = [
            (55.0, 69.30, 82.41, 98.0),
            (58.27, 73.42, 87.31, 110.0),
            (49.0, 61.74, 73.42, 92.5),
            (61.74, 77.78, 92.50, 110.0),
        ]
        kick_gain = 0.34
        snare_gain = 0.20
        hat_gain = 0.09
        pad_gain = 0.13
        arp_gain = 0.10
        bass_gain = 0.18
        delay_mix = 0.44
    else:
        # riftcore / default
        progression = [
            (55.0, 69.3, 82.41, 98.0),
            (61.74, 77.78, 92.5, 110.0),
            (49.0, 61.74, 73.42, 92.5),
            (65.41, 82.41, 98.0, 117.0),
        ]
        kick_gain = 0.66
        snare_gain = 0.38
        hat_gain = 0.16
        pad_gain = 0.09
        arp_gain = 0.17
        bass_gain = 0.24
        delay_mix = 0.34

    for i in range(frames):
        t = i / SR
        bar = int(t / 4.0) % len(progression)
        root, third, fifth, seventh = progression[bar]

        beat = t % 0.5
        kick = 0.0
        if beat < 0.13:
            env = exp_env(beat, 0.13, 2.8)
            freq = 148.0 - 102.0 * (beat / 0.13)
            kick = math.sin(2.0 * math.pi * max(42.0, freq) * t) * env * kick_gain

        snare_phase = (t + 0.25) % 1.0
        snare = 0.0
        if snare_phase < 0.16:
            env = exp_env(snare_phase, 0.16, 2.1)
            noise = random.uniform(-1.0, 1.0)
            tone = math.sin(2.0 * math.pi * 214.0 * t)
            snare = (noise * 0.74 + tone * 0.20) * env * snare_gain

        hat_phase = t % 0.25
        hat = 0.0
        if hat_phase < 0.042:
            env = exp_env(hat_phase, 0.042, 1.3)
            noise = random.uniform(-1.0, 1.0)
            hat = noise * env * hat_gain

        bass = (
            math.sin(2.0 * math.pi * root * t)
            + 0.42 * math.sin(2.0 * math.pi * root * 2.0 * t + 0.18)
        ) * bass_gain

        pad = (
            math.sin(2.0 * math.pi * (third * 0.5) * t + 0.1)
            + math.sin(2.0 * math.pi * (fifth * 0.5) * t + 1.2)
            + math.sin(2.0 * math.pi * (seventh * 0.5) * t + 2.1)
        ) * pad_gain

        arp_step = int(t / 0.125) % 8
        arp_freqs = [root * 2.0, third * 2.0, fifth * 2.0, seventh * 2.0, fifth * 2.0, third * 2.0, root * 2.0, third * 2.0]
        arp_freq = arp_freqs[arp_step]
        arp_local = t % 0.125
        arp_env = exp_env(arp_local, 0.125, 1.6)
        arp = (
            math.sin(2.0 * math.pi * arp_freq * t)
            + 0.28 * math.sin(2.0 * math.pi * arp_freq * 2.0 * t)
        ) * arp_env * arp_gain

        swirl = 0.018 * math.sin(2.0 * math.pi * 0.10 * t)
        core = bass + pad + arp + kick + snare + hat
        left = core + arp * (0.22 + 0.18 * math.sin(2.0 * math.pi * 0.27 * t)) + swirl
        right = core + arp * (-0.22 + 0.18 * math.cos(2.0 * math.pi * 0.29 * t)) - swirl
        out.append((left, right))

    out = apply_delay_stereo(out, delay_seconds=0.22, feedback=0.32, mix=delay_mix)
    out = normalize_stereo(out, peak=0.90)
    write_wav(path, out)


def make_ambient_loop(path: str, mood: str):
    dur = 24.0
    frames = int(SR * dur)
    out = []
    seed = random.Random(999 if mood == "umbra" else 555)
    base = 46.25 if mood == "umbra" else (55.0 if mood == "frost" else (49.0 if mood == "endless" else 61.74))
    drift = 0.25 if mood == "umbra" else 0.18
    air_gain = 0.18 if mood == "frost" else (0.22 if mood == "rift" else 0.20)

    for i in range(frames):
        t = i / SR
        lfo = math.sin(2.0 * math.pi * drift * t)
        f1 = base * (0.5 + 0.02 * lfo)
        f2 = base * (1.0 + 0.03 * math.sin(2.0 * math.pi * (drift * 0.6) * t + 0.7))
        drone = 0.18 * math.sin(2.0 * math.pi * f1 * t) + 0.12 * math.sin(2.0 * math.pi * f2 * t + 1.1)
        noise = seed.uniform(-1.0, 1.0) * 0.10
        shimmer = math.sin(2.0 * math.pi * (base * 6.0) * t + 0.4) * (0.04 + 0.03 * max(0.0, lfo))
        mono = (drone + noise * air_gain + shimmer) * 0.65
        out.append(pan_sample(mono, pan=math.sin(2.0 * math.pi * 0.08 * t) * 0.35))

    out = apply_delay_stereo(out, delay_seconds=0.30, feedback=0.22, mix=0.22)
    out = normalize_stereo(out, peak=0.72)
    write_wav(path, out)


def make_shotgun(seed_value: int = 11, out_name: str = "sfx_shotgun.wav"):
    dur = 0.20
    frames = int(SR * dur)
    mono = []
    seed = random.Random(seed_value)
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
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_beam(detune: float = 0.0, out_name: str = "sfx_beam.wav"):
    dur = 0.24
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.004, 0.03, 0.62, 0.08)
        c = (620.0 + detune) + (820.0 + detune * 0.35) * (t / dur)
        tone = math.sin(2.0 * math.pi * c * t)
        shimmer = math.sin(2.0 * math.pi * c * 1.997 * t + 0.9)
        air = math.sin(2.0 * math.pi * 28.0 * t)
        mono.append((tone * 0.56 + shimmer * 0.23 + air * 0.08) * env)

    out = mono_to_stereo(mono, width=0.38, lfo_hz=9.0)
    out = apply_delay_stereo(out, delay_seconds=0.06, feedback=0.28, mix=0.24)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_boomerang(detune: float = 0.0, out_name: str = "sfx_boomerang.wav"):
    dur = 0.28
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.005, 0.04, 0.44, 0.10)
        wob = math.sin(2.0 * math.pi * 7.0 * t)
        f = (330.0 + detune) + (190.0 + detune * 0.25) * wob
        tone = math.sin(2.0 * math.pi * f * t)
        whoosh = math.sin(2.0 * math.pi * (940.0 + detune * 0.6) * t) * exp_env(t, 0.07, 2.3)
        mono.append((tone * 0.62 + whoosh * 0.14) * env)

    out = mono_to_stereo(mono, width=0.44, lfo_hz=5.2)
    out = apply_delay_stereo(out, delay_seconds=0.08, feedback=0.22, mix=0.22)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, out_name), out)


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


def make_hit(seed_value: int = 23, out_name: str = "sfx_hit.wav"):
    dur = 0.10
    frames = int(SR * dur)
    mono = []
    seed = random.Random(seed_value)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.018, 0.10, 0.04)
        noise = seed.uniform(-1.0, 1.0)
        click = math.sin(2.0 * math.pi * 2700.0 * t) * exp_env(t, 0.02, 2.5)
        mono.append((noise * 0.64 + click * 0.22) * env)

    out = mono_to_stereo(mono, width=0.16, lfo_hz=12.0)
    out = normalize_stereo(out, peak=0.80)
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_crit(detune: float = 0.0, out_name: str = "sfx_crit.wav"):
    dur = 0.14
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.02, 0.35, 0.06)
        sweep = (1200.0 + detune) + (1100.0 + detune * 0.25) * (1.0 - t / dur)
        tone = math.sin(2.0 * math.pi * sweep * t)
        shimmer = math.sin(2.0 * math.pi * (sweep * 2.01) * t + 0.4) * exp_env(t, 0.08, 2.4)
        sub = math.sin(2.0 * math.pi * 120.0 * t) * exp_env(t, 0.06, 3.0)
        mono.append((tone * 0.52 + shimmer * 0.22 + sub * 0.12) * env)

    out = mono_to_stereo(mono, width=0.18, lfo_hz=8.0)
    out = apply_delay_stereo(out, delay_seconds=0.05, feedback=0.18, mix=0.20)
    out = normalize_stereo(out, peak=0.84)
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_hurt(seed_value: int = 19, detune: float = 0.0, out_name: str = "sfx_hurt.wav"):
    dur = 0.18
    frames = int(SR * dur)
    mono = []
    seed = random.Random(seed_value)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.03, 0.28, 0.10)
        freq = (520.0 + detune) - (280.0 + detune * 0.18) * (t / dur)
        tone = math.sin(2.0 * math.pi * max(90.0, freq) * t)
        grit = seed.uniform(-1.0, 1.0) * exp_env(t, dur, 1.7)
        mono.append((tone * 0.46 + grit * 0.28) * env)

    out = mono_to_stereo(mono, width=0.26, lfo_hz=7.0)
    out = apply_delay_stereo(out, delay_seconds=0.07, feedback=0.20, mix=0.22)
    out = normalize_stereo(out, peak=0.84)
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_levelup(transpose: float = 0.0, out_name: str = "sfx_levelup.wav"):
    dur = 0.42
    frames = int(SR * dur)
    mono = []
    chord = [523.25 + transpose, 659.25 + transpose, 783.99 + transpose, 1046.5 + transpose]
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
    write_wav(os.path.join(OUT_DIR, out_name), out)


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


def make_enemy_die(seed_value: int = 77, detune: float = 0.0, out_name: str = "sfx_enemy_die.wav"):
    dur = 0.26
    frames = int(SR * dur)
    mono = []
    seed = random.Random(seed_value)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.04, 0.18, 0.12)
        freq = (420.0 + detune) - (320.0 + detune * 0.20) * (t / dur)
        tone = math.sin(2.0 * math.pi * max(90.0, freq) * t)
        pop = math.sin(2.0 * math.pi * max(70.0, 90.0 + detune * 0.10) * t) * exp_env(t, 0.06, 2.0)
        grit = seed.uniform(-1.0, 1.0) * exp_env(t, dur, 1.6)
        mono.append((tone * 0.44 + pop * 0.25 + grit * 0.28) * env)

    out = mono_to_stereo(mono, width=0.32, lfo_hz=6.4)
    out = apply_delay_stereo(out, delay_seconds=0.06, feedback=0.16, mix=0.18)
    out = normalize_stereo(out, peak=0.84)
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_step(seed_value: int = 101, detune: float = 0.0, out_name: str = "sfx_step.wav"):
    dur = 0.11
    frames = int(SR * dur)
    mono = []
    seed = random.Random(seed_value)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.02, 0.10, 0.06)
        thump = math.sin(2.0 * math.pi * ((110.0 + detune) - 30.0 * (t / dur)) * t) * exp_env(t, 0.05, 2.5)
        noise = seed.uniform(-1.0, 1.0) * exp_env(t, 0.03, 2.0)
        mono.append((thump * 0.32 + noise * 0.10) * env)

    out = mono_to_stereo(mono, width=0.10, lfo_hz=10.0)
    out = normalize_stereo(out, peak=0.70)
    write_wav(os.path.join(OUT_DIR, out_name), out)


def make_click():
    dur = 0.06
    frames = int(SR * dur)
    mono = []
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.001, 0.012, 0.08, 0.03)
        tone = math.sin(2.0 * math.pi * (880.0 + 440.0 * (t / dur)) * t)
        mono.append(tone * env * 0.35)
    out = mono_to_stereo(mono, width=0.12, lfo_hz=9.0)
    out = normalize_stereo(out, peak=0.78)
    write_wav(os.path.join(OUT_DIR, "sfx_click.wav"), out)


def make_boss_roar():
    dur = 0.74
    frames = int(SR * dur)
    mono = []
    seed = random.Random(303)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.01, 0.18, 0.55, 0.22)
        sweep = 90.0 + 240.0 * (1.0 - t / dur)
        rumble = math.sin(2.0 * math.pi * sweep * t) + 0.6 * math.sin(2.0 * math.pi * (sweep * 0.5) * t + 0.6)
        hiss = seed.uniform(-1.0, 1.0) * exp_env(t, dur, 1.2)
        mono.append((rumble * 0.36 + hiss * 0.14) * env)
    out = mono_to_stereo(mono, width=0.28, lfo_hz=2.0)
    out = apply_delay_stereo(out, delay_seconds=0.12, feedback=0.30, mix=0.22)
    out = normalize_stereo(out, peak=0.86)
    write_wav(os.path.join(OUT_DIR, "sfx_boss_roar.wav"), out)


def make_boss_slam():
    dur = 0.36
    frames = int(SR * dur)
    mono = []
    seed = random.Random(515)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.004, 0.08, 0.34, 0.16)
        sweep = 84.0 - 38.0 * (t / dur)
        thump = math.sin(2.0 * math.pi * max(42.0, sweep) * t)
        rumble = math.sin(2.0 * math.pi * max(30.0, sweep * 0.52) * t + 0.6)
        crack = math.sin(2.0 * math.pi * 1700.0 * t) * exp_env(t, 0.05, 2.2)
        grit = seed.uniform(-1.0, 1.0) * exp_env(t, 0.18, 1.8)
        mono.append((thump * 0.55 + rumble * 0.34 + crack * 0.10 + grit * 0.08) * env)

    out = mono_to_stereo(mono, width=0.20, lfo_hz=2.2)
    out = apply_delay_stereo(out, delay_seconds=0.08, feedback=0.22, mix=0.18)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_boss_slam.wav"), out)


def make_boss_die():
    dur = 0.92
    frames = int(SR * dur)
    mono = []
    seed = random.Random(404)
    for i in range(frames):
        t = i / SR
        env = env_adsr(t, dur, 0.008, 0.16, 0.45, 0.32)
        freq = 190.0 - 140.0 * (t / dur)
        boom = math.sin(2.0 * math.pi * max(50.0, freq) * t) * 0.7
        crack = math.sin(2.0 * math.pi * 2100.0 * t) * exp_env(t, 0.05, 2.2)
        noise = seed.uniform(-1.0, 1.0) * exp_env(t, dur, 1.3)
        mono.append((boom * 0.52 + crack * 0.18 + noise * 0.22) * env)
    out = mono_to_stereo(mono, width=0.36, lfo_hz=1.6)
    out = apply_delay_stereo(out, delay_seconds=0.14, feedback=0.26, mix=0.22)
    out = normalize_stereo(out, peak=0.88)
    write_wav(os.path.join(OUT_DIR, "sfx_boss_die.wav"), out)

def main():
    random.seed(1234)
    make_music_loop(os.path.join(OUT_DIR, "music_riftcore.wav"), mood="rift")
    make_music_loop(os.path.join(OUT_DIR, "music_frostfields.wav"), mood="frost")
    make_music_loop(os.path.join(OUT_DIR, "music_umbra_vault.wav"), mood="umbra")
    make_music_loop(os.path.join(OUT_DIR, "music_endless.wav"), mood="endless")
    # Backwards-compatible default (used as fallback).
    make_music_loop(os.path.join(OUT_DIR, "music_loop.wav"), mood="rift")
    make_ambient_loop(os.path.join(OUT_DIR, "ambient_riftcore.wav"), mood="rift")
    make_ambient_loop(os.path.join(OUT_DIR, "ambient_frostfields.wav"), mood="frost")
    make_ambient_loop(os.path.join(OUT_DIR, "ambient_umbra_vault.wav"), mood="umbra")
    make_ambient_loop(os.path.join(OUT_DIR, "ambient_endless.wav"), mood="endless")
    make_shotgun(seed_value=11, out_name="sfx_shotgun.wav")
    make_shotgun(seed_value=17, out_name="sfx_shotgun_2.wav")
    make_shotgun(seed_value=29, out_name="sfx_shotgun_3.wav")
    make_beam(detune=0.0, out_name="sfx_beam.wav")
    make_beam(detune=-42.0, out_name="sfx_beam_2.wav")
    make_beam(detune=58.0, out_name="sfx_beam_3.wav")
    make_boomerang(detune=0.0, out_name="sfx_boomerang.wav")
    make_boomerang(detune=-36.0, out_name="sfx_boomerang_2.wav")
    make_boomerang(detune=52.0, out_name="sfx_boomerang_3.wav")
    make_surge()
    make_hit(seed_value=23, out_name="sfx_hit.wav")
    make_hit(seed_value=31, out_name="sfx_hit_2.wav")
    make_hit(seed_value=47, out_name="sfx_hit_3.wav")
    make_crit(detune=0.0, out_name="sfx_crit.wav")
    make_crit(detune=-120.0, out_name="sfx_crit_2.wav")
    make_hurt(seed_value=19, detune=0.0, out_name="sfx_hurt.wav")
    make_hurt(seed_value=41, detune=-34.0, out_name="sfx_hurt_2.wav")
    make_levelup(transpose=0.0, out_name="sfx_levelup.wav")
    make_levelup(transpose=42.0, out_name="sfx_levelup_2.wav")
    make_levelup(transpose=-36.0, out_name="sfx_levelup_3.wav")
    make_death()
    make_enemy_die(seed_value=77, detune=0.0, out_name="sfx_enemy_die.wav")
    make_enemy_die(seed_value=83, detune=28.0, out_name="sfx_enemy_die_2.wav")
    make_enemy_die(seed_value=97, detune=-24.0, out_name="sfx_enemy_die_3.wav")
    make_step(seed_value=101, detune=0.0, out_name="sfx_step.wav")
    make_step(seed_value=109, detune=8.0, out_name="sfx_step_2.wav")
    make_step(seed_value=113, detune=-7.0, out_name="sfx_step_3.wav")
    make_click()
    make_boss_roar()
    make_boss_slam()
    make_boss_die()
    print("generated", OUT_DIR)


if __name__ == "__main__":
    main()
