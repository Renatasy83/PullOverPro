#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'SKIP native window-size store fixture: requires macOS (mandatory in macOS CI)'
  exit 0
fi
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
xcrun clang -fobjc-arc -Wall -Wextra -Werror -fsanitize=address,undefined \
  -framework Foundation Tweak/POWindowSizeStore.m tests/WindowSizeStoreTests.m \
  -o "$test_dir/window-size-store-tests"
"$test_dir/window-size-store-tests"
