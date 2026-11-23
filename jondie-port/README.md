# PullOver Pro

Pull over any app, anywhere.

![PullOver Pro on an iPhone 11 Pro, iOS 27.2.1: apps pulled over from the handle](screenshots/promo.gif)

- **Pull the handle** at the edge of the screen and your app slides in over the one you are using, still live. Push it back to tuck it away.
- **QuickSwitch:** long-press the handle to pick from your recent apps or favorites. Tap one to pull it over, or drag it to the middle to open it full screen.
- **Settings** apply right away, no respring.

<p>
<img src="screenshots/over.png" width="230" alt="Settings pulled over the Home Screen, showing iOS 27.2.1">
<img src="screenshots/quickswitch.png" width="230" alt="QuickSwitch: drag an app to the middle to open it">
<img src="screenshots/settings.png" width="230" alt="PullOver Pro settings">
</p>

Get it from the [Jond_ie repo](https://jond-ie.github.io/repo/), or from [Releases](https://github.com/Jond-ie/pulloverpro/releases). Rootless and RootHide jailbreaks, iOS 15 to 27. What changed in each version: [CHANGELOG.md](CHANGELOG.md).

## Building

Theos, Rootless scheme:

```
make package THEOS_PACKAGE_SCHEME=rootless
```

The favorites picker uses [AltList](https://github.com/opa334/AltList) at runtime (package dependency).

<details>
<summary>Credits and licence</summary>

Original tweak by c1d3r ([@c1d3rdev](https://x.com/c1d3rdev), [source](https://github.com/c1d3rdev/PullOver-Pro)), GPL-3.0, with iOS 13 support by [@akusio_RR](https://x.com/akusio_RR). Updated for iOS 15 to 27 by Jond_ie ([@Jond_ie](https://x.com/Jond_ie)), under the same GPL-3.0 licence (see LICENSE).
</details>
