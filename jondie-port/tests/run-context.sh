#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_bin="$(mktemp -d)/context-host-tests"
xcrun clang++ -std=c++17 -Wall -Wextra -Werror -fobjc-arc -fblocks \
  -fsanitize=address,undefined -framework Foundation \
  -I tests -DPO_HOSTING_TEST_INTERFACES='"TestContextInterfaces.h"' \
  Tweak/ContextHostManager.mm tests/ContextHostManagerTests.mm -o "$test_bin"
"$test_bin"
