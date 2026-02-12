#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Users/bj/Downloads/Godot.app/Contents/MacOS/Godot}"

run_and_check() {
  local label="$1"
  shift

  local log_file
  log_file="$(mktemp)"
  if ! "$@" >"$log_file" 2>&1; then
    cat "$log_file"
    rm -f "$log_file"
    echo "[smoke] $label failed"
    return 1
  fi

  cat "$log_file"
  if rg -n "SCRIPT ERROR:|Parse Error:|Compile Error:|Failed to load script|Invalid access to property or key|Invalid call\\.|INTEGER_DIVISION" "$log_file" >/dev/null; then
    echo "[smoke] $label found script/runtime errors"
    rm -f "$log_file"
    return 1
  fi

  rm -f "$log_file"
}

echo "[smoke] parse + boot"
run_and_check "parse + boot" "$GODOT_BIN" --headless --path "$ROOT_DIR" --quit

echo "[smoke] gameplay timed run"
run_and_check "gameplay timed run" "$GODOT_BIN" --headless --path "$ROOT_DIR" --scene res://scenes/DebugGame.tscn --quit-after 480

echo "[smoke] endless timed run"
run_and_check "endless timed run" "$GODOT_BIN" --headless --path "$ROOT_DIR" --scene res://scenes/DebugEndless.tscn --quit-after 480

echo "[smoke] passed"
