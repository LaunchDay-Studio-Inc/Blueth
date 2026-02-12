#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ZIP_PATH="${1:-}"
ITCH_TARGET="${ITCH_TARGET:-}"
CHANNEL="${CHANNEL:-html5}"
BUTLER_BIN="${BUTLER_BIN:-}"

if [[ -z "$ZIP_PATH" ]]; then
  ZIP_PATH="$(ls -t "$ROOT_DIR/dist"/Blueth-*-web.zip 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$ZIP_PATH" ]]; then
  echo "Provide a zip artifact path (e.g. dist/Blueth-v0.2.3-web.zip)"
  exit 1
fi

if [[ -z "$ITCH_TARGET" ]]; then
  echo "Set ITCH_TARGET to 'username/project'"
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Missing zip artifact: $ZIP_PATH"
  exit 1
fi

if [[ -z "$BUTLER_BIN" ]]; then
  if command -v butler >/dev/null 2>&1; then
    BUTLER_BIN="$(command -v butler)"
  elif [[ -x "$ROOT_DIR/butler-darwin-amd64/butler" ]]; then
    BUTLER_BIN="$ROOT_DIR/butler-darwin-amd64/butler"
  else
    echo "butler CLI not found. Install from https://itch.io/docs/butler/ or set BUTLER_BIN."
    exit 1
  fi
fi

TMP_DIR="$(mktemp -d)"
unzip -q "$ZIP_PATH" -d "$TMP_DIR"

echo "[itch] using butler: $BUTLER_BIN"
echo "[itch] pushing $ITCH_TARGET:$CHANNEL"
"$BUTLER_BIN" push "$TMP_DIR" "$ITCH_TARGET:$CHANNEL"

rm -rf "$TMP_DIR"
echo "[itch] done"
