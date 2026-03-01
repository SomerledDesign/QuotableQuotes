#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/dist/QuoteableQuotes.saver"
STAGE_DIR="$(mktemp -d /tmp/quoteablequotes-saver.XXXXXX)"
trap 'rm -rf "$STAGE_DIR"' EXIT
STAGE_OUT_DIR="$STAGE_DIR/QuoteableQuotes.saver"
EXE_PATH="$STAGE_OUT_DIR/Contents/MacOS/QuoteableQuotes"
RESOURCE_DIR="$STAGE_OUT_DIR/Contents/Resources"

rm -rf "$OUT_DIR"
mkdir -p "$STAGE_OUT_DIR/Contents/MacOS" "$RESOURCE_DIR"

cp "$ROOT_DIR/SaverBundle/Info.plist" "$STAGE_OUT_DIR/Contents/Info.plist"

# Copy quote XML and bundled backgrounds into the saver bundle resources.
cp -R "$ROOT_DIR/Sources/ScreenSaver/Resources/"* "$RESOURCE_DIR/"
find "$RESOURCE_DIR" -name ".DS_Store" -delete
xattr -cr "$STAGE_OUT_DIR" || true

xcrun swiftc \
  -target arm64-apple-macos13.0 \
  -O \
  -emit-library \
  -module-name QuoteableQuotes \
  -framework AppKit \
  -framework Foundation \
  -framework ScreenSaver \
  "$ROOT_DIR/SaverBundle/QuoteableQuotesView.swift" \
  -o "$EXE_PATH"

# Ad-hoc signing for local install/testing.
if ! codesign --force --deep --sign - "$STAGE_OUT_DIR" >/dev/null 2>&1; then
  echo "Warning: codesign failed in current environment; continuing with unsigned bundle."
fi

cp -R "$STAGE_OUT_DIR" "$OUT_DIR"

echo "Built screensaver bundle:"
echo "  $OUT_DIR"
echo
echo "Install with:"
echo "  scripts/install-saver.sh"
