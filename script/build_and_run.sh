#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CareAssets"
BUNDLE_ID="com.highway.CareAssets.StatusBar"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ROOT="$ROOT_DIR/CareAssets"
BUILD_SCRIPT="$APP_ROOT/build.sh"
APP_BUNDLE="$APP_ROOT/build/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

stop_app() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_app() {
  local module_cache="${TMPDIR:-/private/tmp}/careassets-module-cache"
  mkdir -p "$module_cache"
  SWIFT_MODULECACHE_PATH="$module_cache" CLANG_MODULE_CACHE_PATH="$module_cache" "$BUILD_SCRIPT"
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

verify_app() {
  local running
  running="$(/usr/bin/osascript -e "tell application \"System Events\" to exists process \"$APP_NAME\"")"
  if [ "$running" = "true" ]; then
    echo "$APP_NAME is running"
    return 0
  fi

  echo "$APP_NAME did not start" >&2
  return 1
}

case "$MODE" in
  run)
    stop_app
    build_app
    open_app
    ;;
  --preview|preview)
    stop_app
    build_app
    /usr/bin/open -n "$APP_BUNDLE" --args --preview
    ;;
  --debug|debug)
    stop_app
    build_app
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    stop_app
    build_app
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    stop_app
    build_app
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    stop_app
    build_app
    open_app
    sleep 1
    verify_app
    ;;
  *)
    echo "usage: $0 [run|preview|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
