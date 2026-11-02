# PullOver Pro port

GPL-3.0 port of c1d3r / Will Smillie's PullOver Pro. **1.0.1 RC2** adds guarded application-scene construction without an existing source scene and brings back the compact original-style edge interface: headerless drawer, moving handle/X, narrow recent/favorite column and outside-tap retraction. The rootless Settings page, persisted favorites and isolated owned app windows remain.

The final source `1392af09d382be746ea8ece2a86380a1914fef29` passed **30 automated suites**, Clang analysis, pinned Theos rootless arm64/arm64e compilation and independent artifact/DEB/hash/payload inspection. **Actual cold process startup/rendering/input and the new UIKit integration require a real-device check. Complete Dopamine/ElleKit compatibility, exact original parity and every-app support are unconfirmed.**

[Download RC2 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8d360d8ded7df9e8e857b29088c5642769679172/release-candidates/1.0.1-rc2/com.renatasy83.pulloverpro.diagnostic_1.0.1~rc2_iphoneos-arm64.deb) · [Test report and necessary device check](VALIDATION_1.0.1_RC2.md) · [Classic controls and implementation](CLASSIC_UI_RC2.md) · [Preserved RC1 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8b63669eb2dc68032848843bb0316a76caa71d8a/release-candidates/1.0.0-rc1/com.renatasy83.pulloverpro.diagnostic_1.0.0~rc1_iphoneos-arm64.deb) · [Feature coverage](ORIGINAL_FEATURE_PARITY.md) · [Prior phone evidence](DEVICE_VALIDATION.md)

Install manually with dependencies satisfied, then respring manually. Default windows persist until X or a lifecycle guard; Keep off selects 15-second mode on the next opening. Hold the handle for the compact chooser; double tap for all apps. Other window-size presets retain the toolbar.

Main stays Alpha 4. RC1 source remains at `stable/verified-rc1-safari-kept-resize-manual` and its permanent archive; the older `recovery/0.17.0` package also remains. No automatic phone action, personal-data deletion, other-tweak modification or old preference-domain migration is performed. No compatible physical Apple Silicon Mac is available for vphone-cli. Older documents describe their historical versions.
