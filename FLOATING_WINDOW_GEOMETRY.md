# Floating window geometry — 0.13.0

Isolated branch:debug/floating-window-geometry. This stage adds practical public UIKit window controls to the existing independently owned application windows. Selected-app admission, private owner/proxy binding, client lifecycle, mobile service, native frame, key-window ownership and lock/Keep rules are unchanged. The tested0.12.0 executable is preserved separately.

## Controls and layout

The title remains the drag target. The new ↗ button cycles Medium300x480 -> Large380x680 -> Compact260x420 -> Medium. Available scene size/insets can constrain these dimensions; minimum usable window size is240x320. The close control remains44x44 and the Keep control is80x44. The title drag area remains at least48 points wide at the minimum window width. Resize preserves the center where possible and clamps it within the usable scene. Moves/size changes are not saved to personal preferences or used to reopen scenes.

This is viewport scaling:only PPO's window/root/content and scaling wrapper are changed. The child receives its native screen frame once before containment, exactly as in0.12.0. The app is not told to become an iPad/resizable client, and PPO sends no logical scene resize or unverified private geometry setter. Existing wrapper aspect fit is preserved. Runtime remote input after scaling must still be observed.

Scene-relative safe insets are captured once before creating the small window from at most128 visible full-scene UIWindows via public coordinate conversion and safeAreaInsets, plus a top-aligned public status-bar frame. The pure layout policy adds8-point margins. Floating-window-relative insets are never fed back into movement, preventing position oscillation. If no full-scene inset provider is available, status-bar/bounds margins remain the fallback; this does not prove protection from every system overlay. Size/orientation changes still close under the existing native-size guard rather than introducing unverified rotation behavior.

The pure C++ policy rejects nonfinite/out-of-range rectangles, deltas, insets and presets, clears failed outputs, clamps over/undersized frames and remains idempotent. UIKit actions require an active nonclosing session. Resize and move-begin/end honor the existing lifetime; intermediate movement checks main-thread/closing/pending guards. No action starts/restarts the timer, calls Keep implicitly or changes the owner. Default expiry remains15s; explicit Keep still closes on lock/data/scene guards.

## Evidence and limits

The new side-effect-free suite covers preset bounds, offset/fractional scenes, invalid values,10000 mixed moves/resizes, aspect-fit with the unchanged native414x896 frame, and interleaving geometry with timed/kept lifetime decisions. Local C++17 ASan/UBSan and libstdc++ assertions passed108812 checks. Executablec86083b77575af887973c195e73b0beff28ccfef passed all21 suites, including108812 geometry checks, iOS Clang analysis, Theos rootless arm64/arm64e build and downloaded package/hash inspection in Actions41246925116. Artifact13060155969 contains the candidate/evidence; see VALIDATION_0.13.0.md for exact checksums and unexecuted device tests.

Host report schema9 adds sizePreset, completedMoves/completedResizes, captured placementInsets and wrapperOnlyResize alongside actual ancestor/descendant frames and existing lifecycle/ownership evidence. Only completed controls append events; continuous pan frames do not add unbounded logs. The16-event/eight-session history limits remain. Full runtime compatibility remains false in reports.

The indispensable live gate is one already working app:cycle the three sizes, drag near scene edges, check that X stays reachable and content/scrolling still work, then X/reopen once. It is not a request to repeat app discovery or revalidate every previously working client. Leave Keep off for the short default test; ordinary timeout is preserved. A real iOS compositor, remote input and actual UIKit safe insets cannot be validated by C++ fixtures or macOS Intel CI. No compatible physical Apple Silicon Mac is accessible for vphone-cli.

Recovery:X/default15-second timeout; /var/mobile/.ppo_disable; manual respring for pinned quarantine. If injection prevents startup, start Dopamine without injection and remove only this package. The0.12.0 fallback is Actions41241693750/artifact13057987055. Nothing is installed/resprung automatically, and no personal records or other tweaks are modified. Complete original functionality and full Dopamine/ElleKit compatibility remain unconfirmed.
