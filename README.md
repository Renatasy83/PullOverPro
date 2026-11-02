# PullOver Pro port

GPL-3.0 port of c1d3r / Will Smillie's PullOver Pro. **1.0.2 RC3** adds manual outward handle nubbing and an optional **Evită tastatura** setting for temporary handle/compact-chooser placement. The setting defaults off. Independently owned app scenes and the user-confirmed RC2 Safari source-free/content/navigation/keyboard/X baseline are preserved.

Source `847ba8e8da6d22ffbbf0da42190ed089b6606636` passed **32 automated suites**, Clang analysis, pinned Theos rootless arm64/arm64e compilation and independent artifact/DEB/hash/payload inspection. **The new keyboard-notification and physical-gesture behavior is not yet phone-confirmed. Full Dopamine/ElleKit compatibility, every-app support and exact upstream parity remain unconfirmed.**

[Download RC3 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/87d5d1ef8ddf122edc255c54250694861f6de15d/release-candidates/1.0.2-rc3/com.renatasy83.pulloverpro.diagnostic_1.0.2~rc3_iphoneos-arm64.deb) · [Build/test report and essential new device check](VALIDATION_1.0.2_RC3.md) · [New controls](PUBLIC_KEYBOARD_MANUAL_NUB_RC3.md) · [Preserved RC2 recovery DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8d360d8ded7df9e8e857b29088c5642769679172/release-candidates/1.0.1-rc2/com.renatasy83.pulloverpro.diagnostic_1.0.1~rc2_iphoneos-arm64.deb) · [Prior phone evidence](DEVICE_VALIDATION.md)

Install/respring manually with dependencies satisfied. No automatic phone operation occurs. Existing windows remain in the classic headerless drawer; hold the handle for recent/favorite choices, double tap for the full browser. Own interface diagnostics are `interface-1.0.2.json`; host diagnostics are `host-1.0.2.json` under `/var/mobile/Library/Logs/PullOverPro/`.

`stable/verified-rc2-safari-source-free-classic-reuse` and its permanent package remain unchanged; main stays Alpha4. Private owner/admission/bridge/lock code is unchanged; the owned-trial change is report version/path only. No personal-data deletion, old preference migration or other-tweak modification is performed. No compatible physical Apple Silicon Mac is available for vphone-cli. Older documents describe their historical versions.
