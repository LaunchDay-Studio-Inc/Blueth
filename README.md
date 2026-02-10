# Blueth (Godot 4.6)

`Blueth` is a complete, original arena roguelike MVP inspired by survivor-shooter design patterns.

## Shippable Scope Included

- Complete run loop: menu -> character select -> run -> victory/defeat -> replay.
- Three playable Blueth archetypes:
  - `Blueth Warden` (shotgun)
  - `Blueth Channeler` (beam)
  - `Blueth Drifter` (boomerang)
- Three realm difficulties:
  - `Frostfields` (easier)
  - `Riftcore` (standard)
  - `Umbra Vault` (hard)
- Weapon variety implemented:
  - `Scatter Shot` (spread pellets)
  - `Pulse Beam` (instant piercing line damage)
  - `Arc Boomerang` (returns and can re-hit)
- Progression: 15 realm levels over a 17-minute run, with 30-95 second level pacing.
- Draft system: 4+ upgrade choices, realm-specific upgrades, weapon-specific upgrades, and core overload drafts.
- Meta progression: persistent shard-based skill tree that permanently improves future runs.
- Unique mechanic: `Flow Surge` charges via movement and emits AoE damage + slow.
- Performance-first architecture:
  - pooled enemies/projectiles/xp orbs
  - spawn/active caps
  - low-allocation combat loops
  - 60 FPS project cap (`run/max_fps=60`)
- Original assets:
  - hand-authored SVG hero portraits (`assets/ui`)
  - generated original soundtrack and SFX (`assets/audio`)

## Controls

- Move: `WASD` or arrow keys
- Combat: automatic (nearest-target behavior)

## Run and Validation

### Local play

1. Open in Godot 4.6.
2. Run `res://scenes/Main.tscn` (already configured as main scene).
3. Pick a Blueth build and start run.

### Smoke tests

```bash
./scripts/smoke_test.sh
```

## Build and Release

### 1) Build

```bash
# web only
./scripts/build_release.sh web

# desktop only (macOS + Windows)
./scripts/build_release.sh desktop

# all targets
./scripts/build_release.sh all
```

Note: on first run, `build_release.sh` auto-installs missing Godot export templates (large one-time download) via `scripts/install_export_templates.sh`.

### 2) Package artifacts

```bash
./scripts/package_release.sh v0.2.0
```

Artifacts are written to `dist/`.

### 3) Push web build to itch.io

```bash
export ITCH_TARGET="yourname/blueth"
# required for non-interactive use
export BUTLER_API_KEY="your_api_key"
./scripts/itch_push.sh dist/Blueth-v0.2.0-web.zip
```

## Project Structure

- `project.godot` - project settings
- `export_presets.cfg` - ready export presets (Web/macOS/Windows)
- `scenes/Main.tscn` - main/menu entry scene
- `scenes/DebugGame.tscn` - direct gameplay scene for automated checks
- `scripts/main.gd` - menu + character selection + run orchestration
- `scripts/game/data.gd` - hero, weapon, and realm metadata
- `scripts/game/meta_progression.gd` - persistent shard skill tree
- `scripts/game/game.gd` - full game runtime loop
- `scripts/entities/*.gd` - player/enemy/projectile/xp entities
- `assets/ui/*.svg` - original hero UI art
- `assets/audio/*.wav` - original music/SFX assets
- `scripts/generate_audio_assets.py` - reproducible audio generation script
- `docs/GDD.md` - game design document
- `docs/WORKFLOW_OPTIMIZATION.md` - optimization workflow
- `docs/ITCH_DEPLOY.md` - deployment guide
- `docs/SHIP_CHECKLIST.md` - pre-release QA checklist
- `docs/LEGAL_SAFETY.md` - practical legal-safety checklist
