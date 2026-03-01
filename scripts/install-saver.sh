#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_PATH="$ROOT_DIR/dist/QuoteableQuotes.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

if [[ ! -d "$BUNDLE_PATH" ]]; then
  echo "Bundle not found: $BUNDLE_PATH"
  echo "Run scripts/build-saver.sh first."
  exit 1
fi

mkdir -p "$INSTALL_DIR"
cp -R "$BUNDLE_PATH" "$INSTALL_DIR/"

echo "Installed:"
echo "  $INSTALL_DIR/QuoteableQuotes.saver"
echo
echo "Open System Settings -> Wallpaper -> Screen Saver and select \"Quoteable Quotes\"."
