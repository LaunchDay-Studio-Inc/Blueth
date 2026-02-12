#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
VERSION="${1:-v0.2.7}"

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/Blueth-*.zip

if [[ -d "$ROOT_DIR/build/web" ]]; then
  echo "[package] zipping web build"
  (
    cd "$ROOT_DIR/build/web"
    zip -r "$DIST_DIR/Blueth-${VERSION}-web.zip" . -x "*.import"
  )
fi

if [[ -f "$ROOT_DIR/build/macos/Blueth.zip" ]]; then
  echo "[package] copying macOS build"
  cp "$ROOT_DIR/build/macos/Blueth.zip" "$DIST_DIR/Blueth-${VERSION}-macos.zip"
fi

if [[ -f "$ROOT_DIR/build/windows/Blueth.exe" ]]; then
  echo "[package] zipping windows build"
  (
    cd "$ROOT_DIR/build/windows"
    zip -r "$DIST_DIR/Blueth-${VERSION}-windows.zip" Blueth.exe Blueth.pck 2>/dev/null || zip -r "$DIST_DIR/Blueth-${VERSION}-windows.zip" Blueth.exe
  )
fi

echo "[package] artifacts in $DIST_DIR"
ls -lh "$DIST_DIR"
