#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_PATH="$ROOT_DIR/dist/QuoteableQuotes.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"
TARGET_PATH="$INSTALL_DIR/QuoteableQuotes.saver"

if [[ ! -d "$BUNDLE_PATH" ]]; then
  echo "Bundle not found: $BUNDLE_PATH"
  echo "Run scripts/build-saver.sh first."
  exit 1
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_PATH"
cp -R "$BUNDLE_PATH" "$TARGET_PATH"

echo "Installed:"
echo "  $TARGET_PATH"
echo
echo "Open System Settings -> Wallpaper -> Screen Saver and select \"Quoteable Quotes\"."
