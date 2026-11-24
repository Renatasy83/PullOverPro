#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
if [[ "$(uname -s)" == Darwin ]]; then
  test_cc=(xcrun clang)
else
  test_cc=(cc)
fi
"${test_cc[@]}" -std=c11 -Wall -Wextra -Werror -fsanitize=address,undefined \
  tests/WindowSizeGeometryTests.c -lm -o "$test_dir/window-size-tests"
"$test_dir/window-size-tests"
