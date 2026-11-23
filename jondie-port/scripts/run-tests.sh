#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p diagnostics/tests
expected=(run-context.sh run-keyboard.sh run-preferences.sh run-quickswitch.sh run-startup.sh run-signature.sh)
for test in "${expected[@]}"; do
  if [[ ! -x "tests/$test" ]]; then
    echo "Missing executable test runner: tests/$test" >&2
    exit 1
  fi
done
for runner in tests/run-*.sh; do
  name="$(basename "$runner" .sh)"
  echo "Running $name"
  bash "$runner" 2>&1 | tee "diagnostics/tests/$name.log"
done
