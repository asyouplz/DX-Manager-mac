#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/dxm-native-tests.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
clang -fobjc-arc -fblocks -Wall -Wextra -Werror -mmacosx-version-min=14.0 \
  -framework AppKit -framework Foundation -framework ApplicationServices \
  -framework ScreenCaptureKit -framework Carbon \
  "$repo/build/macos/tests/DesktopControlsTests.m" -o "$work/desktop-tests"
"$work/desktop-tests"
