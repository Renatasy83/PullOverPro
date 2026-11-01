# PullOver Pro port

GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro. **1.0.0 RC1** restores the main original edge-drawer flow and adds a rootless PullOver Pro page in Settings, while retaining the guarded independently owned app scenes. Main stays Alpha4; the last user-confirmed0.17.0 has a permanent recovery DEB.

The candidate includes an80x34 blurred edge capsule, left/right choice, vertical positioning, retained app-content slide, quick recent/favorite selection, central drag/drop normal launch, auto-nub, bounded window sizing, persistent windows and favorite editing/reordering in Settings. Public symbols and PPO’s own recent choices substitute for unverified original icon/switcher APIs. Explicit single-scene/unreviewed clients, full keyboard/focus adaptation and simultaneous windows remain outside this candidate.

Executable `f3653171e59fd04cb2ae0c7b70ba28acf4c20fef` on `debug/original-interface-rc` passed **28 automated suites**, iOS Clang analysis, the pinned Theos rootless arm64/arm64e build and independent downloaded-DEB/hash/payload inspection. The new interface and PreferenceLoader/remote-input integration still need one combined actual-device check. This is the closest implemented candidate, not a fully runtime-validated final port or universal Dopamine/ElleKit compatibility claim.

Use a dependency-aware package manager; PreferenceLoader is required. Install manually and respring. No phone operation runs automatically. Default windows stay open until X or a lifecycle guard; Keep off selects15-second timed mode on the next opening. Recovery and the preserved0.17.0 DEB are in the report.

[Download RC1 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8b63669eb2dc68032848843bb0316a76caa71d8a/release-candidates/1.0.0-rc1/com.renatasy83.pulloverpro.diagnostic_1.0.0~rc1_iphoneos-arm64.deb) · [RC1 package/tests/recovery](VALIDATION_1.0.0_RC1.md) · [Interface/settings guide](ORIGINAL_STYLE_INTERFACE.md) · [Current status](AUTONOMOUS_PORT_STATUS.md) · [Feature coverage](ORIGINAL_FEATURE_PARITY.md) · [Actual phone evidence](DEVICE_VALIDATION.md) · [0.17.0 baseline](VALIDATION_0.17.0.md).

No personal-record deletion, other-tweak modification or old preference-domain migration is performed. Older documents describe their historical versions. General compatibility and original watchdog causes remain unconfirmed; see the evidence limits in the versioned report.
