#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'SKIP native Foundation preferences fixture: requires macOS (mandatory in macOS CI)'
  exit 0
fi
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
xcrun clang -fobjc-arc -Wall -Wextra -Werror -fsanitize=address,undefined \
  -framework Foundation tests/PreferencesTests.m -o "$test_dir/preferences-tests"
"$test_dir/preferences-tests"
