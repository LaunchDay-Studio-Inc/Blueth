# Blueth - Workflow and Optimization Plan

## Strategy

Build complete gameplay first, with performance limits baked in, then iterate by profiling real hotspots.

## Implemented for 60 FPS Stability

- Physics tick fixed at `60 Hz`.
- Frame cap set to `60 FPS`.
- Pooling for enemies, projectiles, and XP orbs.
- Hard cap on active enemies.
- Lightweight enemy AI and collision rules.
- Controlled fire/spawn loop safety guards to prevent frame-time spiral.
- Procedural low-cost effects for surge/beam/muzzle flashes.

## Practical Iteration Loop

1. Add one gameplay feature.
2. Run `./scripts/smoke_test.sh`.
3. Run a stress playtest.
4. Inspect Godot profiler for spikes.
5. Optimize only measured hotspots.
6. Repeat.

## Commands

```bash
# Parse + boot + timed gameplay smoke tests
./scripts/smoke_test.sh

# Build all export targets
./scripts/build_release.sh all
```

`smoke_test.sh` is configured to fail if parse/runtime issues appear in logs (including integer-division warnings), so CI catches breakage early.

## Performance Guardrails

- Keep high-frequency loops allocation-light.
- Reuse pooled nodes; avoid runtime instantiate/free churn in combat.
- Keep upgrade logic data-driven and compact.
- Keep web preset conservative unless your host supports cross-origin isolation for advanced threading.
