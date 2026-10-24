# PullOverPro iOS 26 experimental port

Target: iPhone 11 Pro Max (A13), iOS 26.0.1, Dopamine rootless, ElleKit.

**Status:** source migration / build infrastructure pending. No compatible `.deb` has been built or tested.

Original source: https://github.com/c1d3rdev/PullOver-Pro (GPL-3.0).

The source archive supplied for this work contains a diagnostic-only variant; it must not be treated as an iOS 26 compatible build. Do not install historical .deb binaries from the source archive on iOS 26.

## Test plan

1. Compile a rootless diagnostic-only tweak with an appropriate Theos SDK/toolchain.
2. Confirm safe SpringBoard injection without enabling floating windows.
3. Capture ElleKit/SpringBoard diagnostics and crash reports.
4. Migrate window and application scene hosting APIs incrementally, testing after each stage.

Keep the ability to launch the jailbreak with tweak injection disabled for recovery.
