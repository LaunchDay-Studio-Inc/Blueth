# Blueth - itch.io Deployment Guide

## Release Pipeline

1. Run smoke tests.
2. Build export target(s).
3. Package zipped artifacts.
4. Upload or push to itch.io.

## 1) Smoke Test

```bash
./scripts/smoke_test.sh
```

## 2) Build Exports

```bash
# Web only (recommended first)
./scripts/build_release.sh web

# Desktop only
./scripts/build_release.sh desktop

# All targets
./scripts/build_release.sh all
```

If templates are missing, the script installs them automatically using `scripts/install_export_templates.sh` (one-time large download).

## 3) Package

```bash
./scripts/package_release.sh v0.2.7
```

This writes distributables to `dist/`:

- `Blueth-v0.2.7-web.zip`
- `Blueth-v0.2.7-macos.zip` (if built)
- `Blueth-v0.2.7-windows.zip` (if built)

## 4) Upload to itch.io

### Option A: Web upload in browser

1. Create an itch project with `HTML` type.
2. Upload `dist/Blueth-v0.2.7-web.zip`.
3. Mark it playable in browser.
4. Test controls and fullscreen behavior.

### Option B: Butler push (recommended for updates)

```bash
export ITCH_TARGET="yourname/blueth"
export BUTLER_API_KEY="your_api_key"
./scripts/itch_push.sh dist/Blueth-v0.2.7-web.zip
```

`scripts/itch_push.sh` auto-detects `butler` from `PATH` and falls back to `./butler-darwin-amd64/butler` if present.

## Export Notes

- Export presets are versioned in `export_presets.cfg`.
- Default web preset keeps thread support off for broad host compatibility.
- Desktop codesigning/notarization values are placeholders and should be filled for production store distribution.
