# Application icon parity audit — iOS 26.0.1 / 23A355

This is read-only static research for a later icon stage. No private icon method was called, no production file was edited, and no Apple image asset was copied into the project. Existing public symbols/initials remain the working fallback. This audit does **not** make a private icon path ready for SpringBoard activation.

## Exact image and method evidence

The cache is the existing local arm64e 23A355 cache. UIKitCore UUID is `C98EAB32-B273-3430-B0C5-46522C904CBB`. Additional relevant image UUIDs, read from `LC_UUID`, are:

- IconServices: `B89CC8D1-8087-3923-A4C8-97DCEBA8B4EE`.
- `/System/Library/PrivateFrameworks/SpringBoardHome.framework/SpringBoardHome`: `706559EE-EDF3-3551-B2F1-976BE6AB64F6`.

Do not confuse SpringBoardHome.framework with its similarly named accessibility bundle. Current scene-hosting UUID guards do not already cover SpringBoardHome/IconServices.

Raw method encodings were recovered from the exact class metadata and matched against the addresses in the existing verbose declarations. UIImage has tagged category-list metadata: its root method pointer has bit 0 set; each 8-byte list-list entry carries a signed relative list offset and an image index. Methods with `0x40000000` use selector offsets relative to the optimized selector base `0x1fac19840`, rather than relative to the method entry. The local parser cross-check matched the known selector stub and implementation, so a guessed declaration was not substituted for an encoding.

| Declaring receiver | Selector | Encoding | Implementation |
| --- | --- | --- | --- |
| `UIImage` class | `_applicationIconImageForBundleIdentifier:format:` | `@28@0:8@16i24` | `0x18987e36c` |
| `UIImage` class | `_applicationIconImageForBundleIdentifier:format:scale:` | `@36@0:8@16i24d28` | `0x18987e3f4` |
| `UIImage` class | `_applicationIconImageForBundleIdentifier:format:scale:appearance:style:` | `@52@0:8@16i24d28@36q44` | `0x18987e694` |
| `UIImage` class | `_ISImageDescriptorNameForUIApplicationIconFormat:` | `@20@0:8i16` | `0x18987e210` |
| `UIImage` class | `_baseImageDescriptorForUIApplicationIconFormat:` | `@20@0:8i16` | `0x18987e238` |
| `UIImageAsset` class | `_uncachedDynamicIconAssetNamed:generator:` | `@32@0:8@16@?24` | `0x189883468` |
| `SBIconController` class | `sharedInstanceIfExists` | `@16@0:8` | `0x21d7aff38` |
| `SBIconController` instance | `iconModel` | `@16@0:8` | `0x21d5661a0` |
| `SBIconModel` instance | `applicationIconForBundleIdentifier:` | `@24@0:8@16` | `0x21d7d1080` |
| `SBHIconModel` instance | `applicationIconForBundleIdentifier:` | `@24@0:8@16` | `0x1bdec0d6c` |
| `SBIcon` instance | `iconImageWithInfo:` | `@48@0:8{SBIconImageInfo={CGSize=dd}dd}16` | `0x1be105038` |
| `SBIcon` instance | `iconImageWithInfo:traitCollection:options:` | `@64@0:8{SBIconImageInfo={CGSize=dd}dd}16@48Q56` | `0x1be10504c` |

`format` in UIImage's factory is **int**, not NSInteger. `scale` is double. The appearance variant adds an object and signed long-long style. These UIImage factories follow the normal +0 method-family convention; their bounded assembly also ends in the autorelease-return path. A future adapter must keep the result strongly while it is used, verify that it is actually a UIImage, and not manufacture an initializer/retained-family contract.

`SBIconImageInfo` is 32 bytes: CGSize contains two doubles, followed by scale and continuousCornerRadius doubles. The instance wrapper preserves its four floating arguments in d0–d3, so treating this as an object/pointer argument would be wrong. The smallest `iconImageWithInfo:` wrapper supplies nil traits and options=1 internally before entering the larger image path. This is evidence about that wrapper, not authorization to guess other option bits or pixel sizes.

## What the UIImage path actually does

The three-argument format/scale factory at `0x18987e3f4`:

1. Retains the bundle identifier and forms a string cache key from ID, int format and scale.
2. Allocates an NSMutableDictionary captured by a generator block.
3. Constructs an uncached dynamic UIImageAsset with that generator.
4. Requests an image using UIImageConfiguration's unspecified configuration.

The generator body at `0x18987e560` reads the configuration's system icon appearance or derives one from a UITraitCollection. It keys its mutable dictionary by appearance/style, clears it when regenerating, and delegates to the five-argument factory on a miss. This is not merely reading an existing SBIcon bitmap.

The five-argument factory at `0x18987e694` allocates through **ISIcon**, initializes with the target bundle identifier, obtains an image descriptor for the format, adjusts appearance/style and scale, then calls helper `0x18987e2c0`. That helper invokes `prepareImageForDescriptor:`, obtains the resulting CGImage/scale and constructs a UIImage through `imageWithCGImage:scale:orientation:`. It is a synchronous rendering/preparation path, with no caller-supplied cancellation or timeout.

ISIcon is a class cluster (`+allocWithZone:` at `0x1a720fc3c`), so the allocated instance need not have exact class ISIcon. The corresponding `ISBundleIdentifierIcon -initWithBundleIdentifier:` exists at `0x1a7212398`, encoding `@24@0:8@16`. Its inspected body consults LaunchServices-style bundle records, permits placeholder lookup and has a system-placeholder fallback. A nil/uninstalled/inaccessible ID is not proven to yield nil rather than a generic/placeholder image. Do not equate a nonnil image with installation, ownership or launchability.

`ISIcon -prepareImageForDescriptor:` at `0x1a7210c80` creates/prepares descriptors, obtains an image, tests whether it is a placeholder, and can set `ignoreCache` and retry preparation within IconServices. The path therefore can populate caches and do rendering/lookup work. This audit did not establish the complete lower-level filesystem/XPC behavior or an upper bound for it.

`UIImageAsset -imageWithConfiguration:` at `0x189883e0c` enters its synchronized `_withLock_imageWithConfiguration:` path. That path can call `_withLock_updateAssetFromBlockGenerationWithConfiguration:resolvedCatalogImage:` at `0x18988518c`, which invokes the creation block synchronously at `0x189885200`. The factory being represented as a generator does **not** mean all work is deferred to a safe worker queue or that asking for the image is nonblocking. The mutable captured cache also requires respecting framework execution/serialization rules; this audit has not proved permission for arbitrary background UIKit execution.

No explicit main-thread precondition was identified in these narrow UIImage wrappers. Absence of a visible assertion is not a threading contract. UIScreen/trait collection access, UIImageAsset locks and IconServices preparation remain material. Do not invoke this path from Tweak.xm during bootstrap or synchronously for hundreds of inventory rows. A main-queue timer cannot interrupt one blocked call. This finding does not identify the cause of any previous watchdog report.

## Format values are verified rather than guessed

The exact `UIImage +_ISImageDescriptorNameForUIApplicationIconFormat:` implementation indexes a 17-entry pointer table at `0x1e7308960`; unsigned values greater than16 use a fallback. Relevant verified entries are:

| int format | Descriptor name |
| ---: | --- |
| 0 | `com.apple.IconServices.ImageDescriptor.TableUIName` |
| 1 | `com.apple.IconServices.ImageDescriptor.Spotlight` |
| 2 | `com.apple.IconServices.ImageDescriptor.HomeScreen` |
| 5 | `com.apple.IconServices.ImageDescriptor.Notification` |
| 8 | `com.apple.IconServices.ImageDescriptor.CarLauncher` |
| 9 | `com.apple.IconServices.ImageDescriptor.CarNotification` |
| 10 | `com.apple.IconServices.ImageDescriptor.Activity` |
| 14 | `com.apple.IconServices.ImageDescriptor.MessagesExtensionLauncher` |
| 15 | `com.apple.IconServices.ImageDescriptor.MessagesExtensionBadge` |
| 16 | `com.apple.IconServices.ImageDescriptor.MessagesExtensionStatus` |

The remaining3/4/6/7/11/12/13 entries are document descriptors. `_baseImageDescriptor...` additionally computes a draw-border bit from the format. A table value supplies semantics, not a recommended implementation choice: actual resulting pixel bounds, theme/alternate icon fidelity, scale costs and suitability for PPO's 18/24-point slots remain a device observation.

## Why the original SBIcon code cannot simply be copied

The upstream POApplicationHelper uses `SBIconController.sharedInstance`, `.model`, `expectedIconForDisplayIdentifier:` and `generateIconImageWithInfo:` (or older `generateIconImage:`). Those exact image-generation selectors did not appear in the inspected SBIcon/SBHApplicationIcon method sets. Current SBApplicationIcon adds application/applicationPlaceholder accessors and inherits most image behavior from SpringBoardHome.

On this firmware, the narrower available chain uses `sharedInstanceIfExists`, `iconModel`, `applicationIconForBundleIdentifier:` and `iconImageWithInfo:...`. The existing-instance accessor is not a plain global load: its inspected body performs checks and messaging before reading the singleton; the purpose and threading implications of those checks have not been resolved. The iconModel getter is a small retained/autoreleased field read, but the model's application lookup crosses into its superclass and a generic lookup implementation; the complete model/thread/cache contract is not yet established. The rendering path accepts the structured image info and options and is materially larger than an accessor.

Before considering an SBIcon adapter, complete those invariants and record the actual SpringBoardHome image identity. Do not construct/register an icon or modify the shared model just to obtain an image. Do not use ivar/KVC extraction, swallowed ownership failures, blanket main-thread file reads or guessed option values to bypass unresolved work.

## Public image alternatives

`UIImage imageNamed:inBundle:compatibleWithTraitCollection:` is public and can load ordinary named resources from a supplied bundle, but no public API verified here resolves the correct icon for an arbitrary installed bundle identifier. Icon sets in Assets.car, alternate icons, dynamic system icons and per-appearance variants are not equivalent to an ordinary PNG by a guessed filename. Reading CFBundleIcons/CFBundleIconFiles names does not establish a universal usable image path.

If a later helper supplies bounded icon data from an already admitted installed bundle, it needs explicit file/type/path/size/ownership rules and must not expose arbitrary app-container paths or read user documents. UIKit decoding, asset rendering, freshness, theme/alternate icon changes and memory limits still require design and tests. Do not copy firmware icon assets into the GPL package; use installed system resources only under an appropriate runtime contract.

The current symbols/initials are the reliable fallback. This stage should remain research while the independent public keyboard/manual-nub changes proceed.

## Remaining gate before activation

An actual icon implementation needs a separately reviewable adapter and tests for method/class/UUID/argument-type refusal, bounded immutable ID/request keys, single in-flight work, cache limits, stale selection/theme generations, nil/exception results, placeholder handling, and fallback. It also needs a justified execution context: no unbounded SpringBoard main-thread loading and no assumed worker-safe UIKit operation. A helper alternative cannot assume its SpringBoard/IconServices entitlements or loading context.

The indispensable real-device icon gate would compare a known icon, a third-party icon and an unavailable result against the safe fallback; observe scrolling/hover/handle responsiveness, appearance changes and bounded memory; and capture diagnostics. That gate is not requested now, since no private icon code was enabled and the public UI stage does not depend on it.

Local raw evidence remains outside the repository: `/workspace/icon-*.asm`, `/workspace/icon-objc-research.py`, `/workspace/icon-annotate.py`, the existing verbose UIKitCore/SpringBoard dumps and the cached images. Only this derived audit should be considered for a source commit; do not commit the Apple cache or disassembly bytes.
