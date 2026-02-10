#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Users/bj/Downloads/Godot.app/Contents/MacOS/Godot}"
OUT_PATH="${1:-$ROOT_DIR/build/web/index.html}"

mkdir -p "$(dirname "$OUT_PATH")"
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Web" "$OUT_PATH"

echo "Export complete: $OUT_PATH"
