#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${THEOS:?Set THEOS to a configured Theos checkout}"
mkdir -p diagnostics/analysis
perl "$THEOS/vendor/logos/bin/logos.pl" Tweak/Tweak.xm > diagnostics/analysis/Tweak.mm
flags=(-fobjc-arc -target arm64-apple-ios15.0 -isysroot "$THEOS/sdks/iPhoneOS16.5.sdk"
  -I "$THEOS/vendor/include" -I "$THEOS/include" -I Tweak -I Shared
  -F "$THEOS/vendor/lib/iphone/rootless" -F "$THEOS/vendor/lib/iphone" -F "$THEOS/vendor/lib"
  '-DTHEOS_PACKAGE_INSTALL_PREFIX="/var/jb"'
  -Wno-deprecated-declarations -Wno-unused-variable -Wno-objc-property-no-attribute -Wno-incomplete-implementation)
failed=0
for source in diagnostics/analysis/Tweak.mm Tweak/*.m Tweak/*.mm Prefs/*.m; do
  output="diagnostics/analysis/$(basename "$source").plist"
  if [[ "$source" == *.mm ]]; then
    compiler=(xcrun clang++ -x objective-c++ -std=c++17)
  else
    compiler=(xcrun clang -x objective-c)
  fi
  if ! "${compiler[@]}" --analyze "${flags[@]}" \
    -Xanalyzer -analyzer-output=plist -Xanalyzer -analyzer-werror "$source" -o "$output"; then
    failed=1
  fi
done
python3 - <<'PY'
import pathlib, plistlib
files = sorted(pathlib.Path('diagnostics/analysis').glob('*.plist'))
assert files, 'No analyzer outputs'
for path in files:
    with path.open('rb') as stream:
        report = plistlib.load(stream)
    assert not report.get('diagnostics'), f'Clang analyzer findings in {path}'
print(f'Clang analysis: {len(files)} production translation units, zero analyzer findings')
PY
test "$failed" -eq 0
