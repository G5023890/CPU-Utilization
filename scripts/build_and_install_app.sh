#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="CPU MenuBar"
SCHEME="CPU MenuBar"
APP_NAME="CPU MenuBar.app"
INSTALL_PATH="/Applications/CPU MenuBar.app"

log() {
  echo "[build] $*"
}

log "Building ${PROJECT_NAME}"
xcodebuild \
  -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  build

BUILD_APP_PATH="$(
  xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Debug \
    -showBuildSettings \
  | awk -F ' = ' '/^[[:space:]]*BUILT_PRODUCTS_DIR = / {built=$2} /^[[:space:]]*FULL_PRODUCT_NAME = / {product=$2} END {print built "/" product}'
)"

if [[ ! -d "$BUILD_APP_PATH" ]]; then
  echo "Built app not found: $BUILD_APP_PATH" >&2
  exit 1
fi

log "Installing to ${INSTALL_PATH}"
rm -rf "$INSTALL_PATH"
/usr/bin/ditto --norsrc "$BUILD_APP_PATH" "$INSTALL_PATH"

log "Stopping any existing app"
killall "CPU MenuBar" >/dev/null 2>&1 || true

log "Launching installed app"
open -n "$INSTALL_PATH"

log "Installed and relaunched from ${INSTALL_PATH}"
