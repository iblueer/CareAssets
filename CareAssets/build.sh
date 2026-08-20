#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="CareAssets"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
FONTS_DIR="$RESOURCES_DIR/Fonts"
SEN_FONT="$ROOT_DIR/Resources/Fonts/Sen-Medium.ttf"
SEN_LICENSE="$ROOT_DIR/Resources/Fonts/Sen-OFL.txt"
APP_ICON_SVG="$ROOT_DIR/Resources/AppIcon.svg"
APP_ICON_ICNS="$ROOT_DIR/Resources/AppIcon.icns"
APP_LOGO_SVG="$ROOT_DIR/Resources/AppLogo.svg"
APP_LOGO_PNG="$ROOT_DIR/Resources/AppLogo.png"
MACOS_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET:-12.0}"
ARCHS="${ARCHS:-arm64 x86_64}"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$FONTS_DIR"

generate_icon_assets() {
  [ -f "$APP_ICON_SVG" ] || return 1
  command -v sips >/dev/null || return 1
  command -v iconutil >/dev/null || return 1

  local iconset="$BUILD_DIR/CareAssets.iconset"
  local base_png="$BUILD_DIR/AppIcon-1024.png"
  rm -rf "$iconset"
  mkdir -p "$iconset"
  sips -z 1024 1024 -s format png "$APP_ICON_SVG" --out "$base_png" >/dev/null || return 1

  make_icon_png() {
    local size="$1"
    local name="$2"
    sips -z "$size" "$size" "$base_png" --out "$iconset/$name" >/dev/null || return 1
  }

  make_icon_png 16 icon_16x16.png
  make_icon_png 32 icon_16x16@2x.png
  make_icon_png 32 icon_32x32.png
  make_icon_png 64 icon_32x32@2x.png
  make_icon_png 128 icon_128x128.png
  make_icon_png 256 icon_128x128@2x.png
  make_icon_png 256 icon_256x256.png
  make_icon_png 512 icon_256x256@2x.png
  make_icon_png 512 icon_512x512.png
  make_icon_png 1024 icon_512x512@2x.png

  iconutil -c icns "$iconset" -o "$RESOURCES_DIR/CareAssets.icns" >/dev/null || return 1
  if [ -f "$APP_LOGO_SVG" ]; then
    sips -z 64 64 -s format png "$APP_LOGO_SVG" --out "$RESOURCES_DIR/AppLogo.png" >/dev/null || return 1
  else
    sips -z 64 64 "$base_png" --out "$RESOURCES_DIR/AppLogo.png" >/dev/null || return 1
  fi
}

cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$SEN_FONT" "$FONTS_DIR/Sen-Medium.ttf"
cp "$SEN_LICENSE" "$FONTS_DIR/Sen-OFL.txt"
[ -f "$APP_ICON_SVG" ] && cp "$APP_ICON_SVG" "$RESOURCES_DIR/AppIcon.svg"
[ -f "$APP_ICON_ICNS" ] && cp "$APP_ICON_ICNS" "$RESOURCES_DIR/CareAssets.icns"
[ -f "$APP_LOGO_SVG" ] && cp "$APP_LOGO_SVG" "$RESOURCES_DIR/AppLogo.svg"
[ -f "$APP_LOGO_PNG" ] && cp "$APP_LOGO_PNG" "$RESOURCES_DIR/AppLogo.png"
generate_icon_assets || true

binaries=()
SOURCE_FILES=("$ROOT_DIR"/Sources/CareAssets/*.swift)
for arch in $ARCHS; do
  binary="$BUILD_DIR/$APP_NAME-$arch"
  xcrun swiftc \
    -target "$arch-apple-macosx$MACOS_DEPLOYMENT_TARGET" \
    -sdk "$SDK_PATH" \
    "${SOURCE_FILES[@]}" \
    -framework AppKit \
    -framework CoreText \
    -framework Foundation \
    -lsqlite3 \
    -o "$binary"
  binaries+=("$binary")
done

if [ "${#binaries[@]}" -eq 1 ]; then
  cp "${binaries[0]}" "$MACOS_DIR/$APP_NAME"
else
  xcrun lipo -create "${binaries[@]}" -output "$MACOS_DIR/$APP_NAME"
fi

codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
