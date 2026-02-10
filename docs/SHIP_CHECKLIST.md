# Blueth Ship Checklist

## Gameplay QA

- [ ] Run at least one full 17-minute victory run.
- [ ] Run at least one early-death fail-state run.
- [ ] Verify all three heroes are selectable and start with correct weapon types.
- [ ] Verify all three realms are selectable and difficulty/reward differences feel clear.
- [ ] Verify end-of-run mastery shards are granted.
- [ ] Verify shard skill tree upgrades persist after restart.
- [ ] Verify upgrades appear and can be selected repeatedly.
- [ ] Verify Flow Surge triggers and affects enemies.

## Performance QA

- [ ] Confirm FPS remains near 60 during mid/late waves on target hardware.
- [ ] Check for frame spikes while many enemies are active.
- [ ] Confirm no runaway spawn/projectile behavior after long play sessions.

## Build QA

- [ ] `./scripts/smoke_test.sh` passes.
- [ ] `./scripts/build_release.sh web` completes.
- [ ] `./scripts/package_release.sh vX.Y.Z` produces `dist/` zip(s).
- [ ] Web zip launches and accepts keyboard input in browser.

## itch.io Release QA

- [ ] Upload `dist/Blueth-vX.Y.Z-web.zip`.
- [ ] Verify game starts in embedded iframe.
- [ ] Verify controls and fullscreen on itch page.
- [ ] Update itch page copy/screenshots/changelog.

## Versioning

- [ ] Tag release commit.
- [ ] Archive artifacts for rollback.
- [ ] Record release notes in repo/docs.
