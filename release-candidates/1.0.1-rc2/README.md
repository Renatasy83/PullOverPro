# PullOver Pro 1.0.1 RC2 archive

Rootless candidate: guarded source-independent application scenes and classic headerless edge UI. This is the single candidate from the final successful build. It has not run on the target phone; Dopamine/ElleKit compatibility, cold process admission/rendering/input and the new UI are unconfirmed.

- Executable source: `1392af09d382be746ea8ece2a86380a1914fef29`.
- Actions: https://github.com/Renatasy83/PullOverPro/actions/runs/41390672326
- Artifact: `13117841813`; 30 successful suite logs, Clang analysis, Theos rootless arm64/arm64e, package/lifecycle/license checks.
- Downloaded ZIP and DEB hashes, binaries, production cold/classic markers and rootless payload independently inspected.
- DEB SHA256: `a98d7c615e2fdc92f90a33c61f993bd87473e0aec8e786d2fcb54c29673fa655`.
- ZIP SHA256: `365567ebedf670167c3da6a234068007ee9addfddd43bee05b8956dcdc020bf1`.

Install manually with dependencies satisfied, then respring manually. No installation or phone operation is automated. For the essential cold test, close PPO's owned window, remove Safari from the iOS app switcher, stay in NewTerm and open its PPO favorite without normally opening Safari first. Check first content/input, X and reopening; send `/var/mobile/Library/Logs/PullOverPro/host-1.0.1.json`. Confirm the compact list and headerless drawer in the same session. A warm-source success is not proof of cold launch.

Recovery: RC1 remains archived at commit `8b63669eb2dc68032848843bb0316a76caa71d8a` on `release-candidates/1.0.0-rc1`; stable executable branch `stable/verified-rc1-safari-kept-resize-manual` remains unchanged. Existing `/var/mobile/.ppo_disable` plus manual respring, or Dopamine startup without tweak injection then uninstalling only PPO, are recovery routes. Main and other tweaks/personal data are unchanged. GPL-3.0 source and attribution remain included.

The machine report distinguishes synthetic fixtures from iOS runtime tests. No compatible physical Apple Silicon Mac is available for vphone-cli.
