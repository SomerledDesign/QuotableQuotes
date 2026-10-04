#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XIB_PATH="$ROOT_DIR/Sources/ScreenSaver/Resources/DisplayOptionsView.xib"
NIB_PATH="$ROOT_DIR/Sources/ScreenSaver/Resources/DisplayOptionsView.nib"

ibtool --compile "$NIB_PATH" "$XIB_PATH"
echo "Compiled $XIB_PATH -> $NIB_PATH"
