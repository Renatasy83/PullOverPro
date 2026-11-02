# RC3 — public keyboard avoidance and manual handle nub

Version **1.0.2~rc3** retains RC2's independently owned app scenes and source-free Safari baseline. The protected host constructors, admission, proxy binding, activation, lock/lifetime/cleanup and bridge are unchanged. The only owned-trial change is the report version/path. Main and `stable/verified-rc2-safari-source-free-classic-reuse` remain untouched; its permanent RC2 DEB is the recovery package.

## Implemented

A direction-locked closed-handle drag towards the outside edge can manually retract the capsule to the existing nub geometry. This works independently of automatic hiding. Tap, inward opening or long press reveals it. A pending/outward/vertical/cancelled gesture cannot enter the app inspection path; only an ordinary drawer decision can start its existing held intent. Invalid samples retract a partly moved public drawer and cancel the request. Minimum touch geometry remains reachable. Explicit nub state is per SpringBoard session, not written into another preference domain.

Settings adds **Evită tastatura**, a strict Boolean that defaults off and preserves old settings. Public keyboard end-frame notifications are converted from the scene's screen space into its coordinate space. Invalid, stale, inactive/locked or changed-display metadata becomes unknown. Missing notifications are not proof of an absent keyboard. No private keyboard/focus/key-window API is added.

When enabled, the policy moves an overlapping handle into a safe vertical band and constrains only the compact chooser; a docked full-width keyboard can constrain the chooser even if the handle already clears it. Floating keyboard data affects placement only on actual handle overlap. Short bands refuse the compact chooser. Changing effective geometry cancels held selection before rows move. Hiding the keyboard restores the configured position. Notification-driven movement never writes the stored ratio; an intentional vertical drag uses the actual displayed handle and remains an explicit position edit. App panel/native frames and keyboard focus are unchanged. This does not implement dedicated floating-app keyboard routing or the original iOS13 external-keyboard scene-stack behavior.

Own-interface diagnostics are at `/var/mobile/Library/Logs/PullOverPro/interface-1.0.2.json`: a capped 16-observation history, public notification count/status, adjustment and manual-nub events. No text, web content or inventory is captured. One worker write and one latest pending snapshot are allowed; no diagnostic file I/O runs in keyboard callbacks. The ordinary scene report is `host-1.0.2.json`.

## Automation and remaining real gate

CI requires 32 suite logs, Clang analysis including the public monitor, native preference tests, pinned Theos rootless arm64/arm64e compilation and payload/lifecycle/license/hash checks. Local pure ASan/UBSan checks include keyboard geometry and direction/nub policy. These fixtures do not deliver actual UIKit notifications or physical gestures. Actual notification delivery in SpringBoard, the manual outward gesture and temporary movement/restoration remain unverified on RC3.

After a successful candidate build, the only new combined phone check is: with PPO retracted, drag the handle outward and tap to reveal it; enable Evită tastatura in Settings, place the handle low with the keyboard hidden, then show/hide NewTerm's keyboard and check temporary movement/restoration. Send `interface-1.0.2.json`. No app-by-app or source-free Safari replay is requested. If notification count stays zero, do not infer that avoidance was exercised or force private keyboard access. The old RC2 build stays available for recovery.

An independent icon parity audit is recorded in `ICON_PARITY_AUDIT_23A355.md`. It found synchronous private icon rendering with unresolved execution/I/O contracts. Those APIs are not enabled in this public UI stage; public symbols/initials remain. No compatible physical Apple Silicon Mac is available for vphone-cli. Successful CI is not full Dopamine/ElleKit runtime confirmation.
