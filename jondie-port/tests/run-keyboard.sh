#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
cc -std=c11 -Wall -Wextra -Werror -fsanitize=address,undefined KeyboardTests.c -lm -o "$out/test"
"$out/test"
