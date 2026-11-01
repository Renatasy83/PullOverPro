# Preserved PullOver Pro 0.17.0 recovery package

This directory retains the exact user-tested0.17.0 package independently of GitHub Actions artifact expiry. It is an operation-specific recovery baseline, not a claim that every app or general Dopamine/ElleKit compatibility is verified.

- Package: `com.renatasy83.pulloverpro.diagnostic_0.17.0~dev.namedconfigs1_iphoneos-arm64.deb`
- DEB SHA256: `0e2d6a5792167e29d3eec58f843b3fc121efb93b51c20a0bf70703c530010bda`
- Exact executable/source: [`ad6ece8c6cbde196cc4be1ee0b2910cd9c832134`](https://github.com/Renatasy83/PullOverPro/tree/ad6ece8c6cbde196cc4be1ee0b2910cd9c832134)
- Original successful build: [Actions41306271038](https://github.com/Renatasy83/PullOverPro/actions/runs/41306271038), [artifact13083582354](https://github.com/Renatasy83/PullOverPro/actions/runs/41306271038/artifacts/13083582354).

The full corresponding source and build scripts are inherited at this branch's root. The executable commit above pins them even if this recovery README changes. Original PullOver Pro is by c1d3r / Will Smillie, https://github.com/c1d3rdev/PullOver-Pro. This port and package are distributed under GPL-3.0; [the full LICENSE](../../LICENSE) and [packaged copyright/attribution](../../layout/usr/share/doc/com.renatasy83.pulloverpro.diagnostic/copyright) are included. No raw phone report or personal application content is stored here.

For manual rollback only: download this DEB and check SHA256 before installing with your package manager. This file performs no automatic installation or respring. The package ID is unchanged. If injection prevents startup, start Dopamine without tweak injection and remove only PullOver Pro. Existing disable marker: `/var/mobile/.ppo_disable`. Consult the version-specific source docs before a new test; compilation alone is not runtime verification.
