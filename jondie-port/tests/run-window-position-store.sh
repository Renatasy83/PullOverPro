#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'SKIP native window-position store fixture: requires macOS (mandatory in macOS CI)'
  exit 0
fi
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
xcrun clang -fobjc-arc -Wall -Wextra -Werror -fsanitize=address,undefined \
  -framework Foundation Tweak/POWindowPositionStore.m tests/WindowPositionStoreTests.m \
  -o "$test_dir/window-position-store-tests"
"$test_dir/window-position-store-tests"
