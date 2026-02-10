# Blueth - Game Design Document

## Product Goal

Ship an original, lightweight roguelike arena game that is inspired by survivor-shooter pacing while using unique names, original art/audio, and differentiated mechanics.

## Core Fantasy

You are Blueth, a bio-gel survivor fighting through escalating waves in a sealed arena where movement itself powers your strongest ability.

## Player-Visible Pillars

- Mobility powers offense.
- Distinct playable builds with different weapon identities.
- Fast, readable combat at stable framerate.
- Full-length runs with clear win/loss states and strong meta reward.

## Playable Characters

1. Blueth Warden
- Role: durable close-range pressure
- Starter weapon: `Scatter Shot` (shotgun)

2. Blueth Channeler
- Role: precision lane control
- Starter weapon: `Pulse Beam` (instant line damage)

3. Blueth Drifter
- Role: high-mobility sustained control
- Starter weapon: `Arc Boomerang` (returning projectile)

## Unique Mechanic

### Flow Surge

- Movement charges a hidden distance meter.
- When charged, Blueth emits an AoE pulse.
- Pulse deals damage and slows nearby enemies.
- Encourages active movement patterns over static kiting.

## Core Loop

1. Pick character loadout in menu.
2. Pick realm difficulty.
3. Spend persistent mastery shards in the skill tree.
4. Enter arena.
5. Auto-attack with chosen weapon type.
6. Move to dodge and charge Flow Surge.
7. Kill enemies and collect XP orbs.
8. Trigger level/core drafts and choose upgrades.
9. Survive full timer (victory) or die (defeat).

## Progression System

- 15 realm levels are time-gated to stabilize pacing.
- Level duration target: 30 seconds to 3 minutes.
- Upgrades include core stats, weapon-specific modifiers, and realm-specific options.
- Core charge overload events grant extra draft windows.
- Persistent meta progression:
  - mastery shards awarded on run end
  - shard skill tree permanently boosts future runs
- Upgrade examples:
  - global damage/fire rate/speed/max HP
  - beam width (beam only)
  - extra shotgun pellet (shotgun only)
  - extra boomerang hit cycle (boomerang only)

## Enemy Model

- Standard chaser enemy.
- Elite variant with stronger stats and XP value.
- Time-based scaling for HP/speed/damage/spawn pressure.
- Realm-based tuning multipliers for HP/speed/damage/spawn cadence.

## Realm Model

- Frostfields: safer, slower, lower rewards.
- Riftcore: baseline challenge and rewards.
- Umbra Vault: high pressure, higher rewards.

## Run Targets

- Run duration: 17:00.
- Realm levels: 15.
- Success condition: survive full timer.
- Failure condition: HP reaches 0.

## Art and Audio Direction

- Original vector-style hero portraits and UI motifs.
- Original generated soundtrack and SFX shipped in-repo.
- No third-party trademarked logos, names, or copied sprites/UI layouts.

## Technical Constraints

- Godot 4.6.
- 60 Hz physics and 60 FPS target.
- Pooling and spawn caps as first-class requirements.
- Web export compatibility prioritized.
