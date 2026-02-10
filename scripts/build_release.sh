#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Users/bj/Downloads/Godot.app/Contents/MacOS/Godot}"
TARGETS="${1:-web}"
TEMPLATE_DIR="${HOME}/Library/Application Support/Godot/export_templates/4.6.stable"

run_export() {
  local preset="$1"
  local output="$2"
  echo "[build] $preset -> $output"
  mkdir -p "$(dirname "$output")"
  "$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "$preset" "$output"
}

ensure_templates_for_target() {
  local targets="$1"
  local needs_install=0

  if [[ "$targets" == "web" || "$targets" == "all" ]]; then
    [[ -f "$TEMPLATE_DIR/web_nothreads_release.zip" ]] || needs_install=1
  fi
  if [[ "$targets" == "desktop" || "$targets" == "all" ]]; then
    [[ -f "$TEMPLATE_DIR/macos.zip" ]] || needs_install=1
    [[ -f "$TEMPLATE_DIR/windows_release_x86_64.exe" ]] || needs_install=1
  fi

  if [[ "$needs_install" -eq 1 ]]; then
    echo "[build] missing export templates, installing..."
    "$ROOT_DIR/scripts/install_export_templates.sh"
  fi
}

"$ROOT_DIR/scripts/smoke_test.sh"
ensure_templates_for_target "$TARGETS"

if [[ "$TARGETS" == "all" ]]; then
  run_export "Web" "$ROOT_DIR/build/web/index.html"
  run_export "macOS" "$ROOT_DIR/build/macos/Blueth.zip"
  run_export "Windows Desktop" "$ROOT_DIR/build/windows/Blueth.exe"
elif [[ "$TARGETS" == "web" ]]; then
  run_export "Web" "$ROOT_DIR/build/web/index.html"
elif [[ "$TARGETS" == "desktop" ]]; then
  run_export "macOS" "$ROOT_DIR/build/macos/Blueth.zip"
  run_export "Windows Desktop" "$ROOT_DIR/build/windows/Blueth.exe"
else
  echo "Unknown target set: $TARGETS"
  echo "Use: web | desktop | all"
  exit 1
fi

echo "[build] done"
