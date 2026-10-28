# Run using an existing shell: /var/jb/bin/sh scripts/build-local.sh
set -eu
export LC_ALL=C
export LANG=C
export PATH="/var/jb/usr/bin:/var/jb/bin:$PATH"
: "${THEOS:=/var/jb/var/mobile/theos}"
export THEOS
test -f "$THEOS/makefiles/common.mk" || {
    echo "Missing Theos: $THEOS" >&2
    exit 1
}
test -d "$THEOS/sdks/iPhoneOS16.5.sdk" || {
    echo "Missing SDK: $THEOS/sdks/iPhoneOS16.5.sdk" >&2
    exit 1
}
ppo_shell=
for candidate in /var/jb/bin/bash /var/jb/usr/bin/bash /bin/bash; do
    if test -x "$candidate"; then ppo_shell="$candidate"; break; fi
done
test -n "$ppo_shell" || { echo "Theos requires an executable bash" >&2; exit 1; }
echo "Theos=$THEOS; SHELL=$ppo_shell"
make --version | head -n 1
clang --version | head -n 1
# A command-line SHELL propagates through recursive make. Never create /bin/sh.
make SHELL="$ppo_shell" clean
make SHELL="$ppo_shell" package FINALPACKAGE=1
for deb in packages/*0.7.0~dev.sceneselect1*iphoneos-arm64.deb; do
    test -f "$deb" || { echo "Missing diagnostic deb" >&2; exit 1; }
    dpkg-deb -f "$deb" Package Version Architecture Depends
    dpkg-deb -c "$deb"
done

