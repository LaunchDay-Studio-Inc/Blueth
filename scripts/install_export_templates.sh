#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.6-stable}"
GODOT_VERSION_DIR="${GODOT_VERSION_DIR:-4.6.stable}"
TEMPLATE_URL="${TEMPLATE_URL:-https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz}"
TARGET_DIR="${HOME}/Library/Application Support/Godot/export_templates/${GODOT_VERSION_DIR}"
TMP_DIR="$(mktemp -d)"
TPZ_PATH="$TMP_DIR/templates.tpz"

echo "[templates] target dir: $TARGET_DIR"
if [[ -f "$TARGET_DIR/web_nothreads_release.zip" && -f "$TARGET_DIR/macos.zip" && -f "$TARGET_DIR/windows_release_x86_64.exe" ]]; then
  echo "[templates] already installed"
  exit 0
fi

mkdir -p "$TARGET_DIR"

echo "[templates] downloading $TEMPLATE_URL"
curl -L --fail --silent --show-error "$TEMPLATE_URL" -o "$TPZ_PATH"

echo "[templates] extracting"
unzip -q "$TPZ_PATH" -d "$TMP_DIR/unpack"

if [[ ! -d "$TMP_DIR/unpack/templates" ]]; then
  echo "[templates] invalid archive layout"
  exit 1
fi

cp -f "$TMP_DIR/unpack/templates"/* "$TARGET_DIR/"
rm -rf "$TMP_DIR"

echo "[templates] installed"
ls -1 "$TARGET_DIR" | head -30
