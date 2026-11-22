# Existing PullOver Pro port identified by the user

Inspected2026-11-22 through public GitHub repository files. This is a reference checkpoint, not an installation or runtime test.

## Package and source

- Repository: https://jond-ie.github.io/repo/
- Package: com.johndie.pulloverpro-rootless, version3.0.1.
- Source: https://github.com/Jond-ie/pulloverpro at `076da8f07e707453bc58ed9baadeefb40f0e93e4`, GPL-3.0. The package repo README explicitly identifies it as source.
- Package index: https://github.com/Jond-ie/repo/blob/84183ec8b6c3bce2d777575264d4380ebf6740f1/Packages
- Depiction: https://jond-ie.github.io/repo/depictions/com.johndie.pulloverpro-rootless.json
- Source Makefile: rootless Theos; arm64/arm64e; SDK16.5/deployment15.0; Tweak and Prefs subprojects.
- Runtime dependencies: mobilesubstrate and AltList (com.opa334.altlist); firmware>=15,<28; PreferenceLoader recommended.

The index lists3.0.1:

| Architecture | Bytes | SHA256 |
| --- | ---: | --- |
| iphoneos-arm64 | 70528 | 65c5cffbb07fdbde599c8d11b4ab95301702de0bdd92b1da35fd8c7a2d4d5895 |
| iphoneos-arm64e | 68204 | e50ba2c9bec30a0284ea8a4fe76cee5521b3aaaf3abee7912ee74acd7b95bd5c |

These are index hashes; the binary files were not downloaded or independently rehashed at this checkpoint.

## Upstream statements, explicitly attributed

README/depiction describe the original pull-out edge interface, recent/favorite QuickSwitch, full-screen drop target and Settings applied live. The beta changelog says apps not already running start in the background. The paid unlock was removed and source remains GPL.

The author advertises iOS15–27 and Rootless/RootHide. Depiction says3.0.1 was checked on iPhoneXR/iOS16.0.3;3.0.0 was manually tested on iPhone11Pro/iOS27.2.1; earlier builds ran on iPhone11ProMax/iOS16.2 and a RootHide virtual iPhone. The iOS17 handle-startup fix is stated as not yet confirmed on an iOS17 phone. These claims were read, not independently reproduced here; they do not establish this user's exact iOS26.0.1/Dopamine/ElleKit compatibility.

Upstream also states that an app already open full screen cannot be pulled over at the same time. Source comparison must account for that workflow difference from the custom Messenger warm-host trials.

## Direction for continuation

Evaluate this existing implementation before further bespoke candidate development. Preserve all local work/recovery archives and upstream GPL/c1d3r/Jond_ie attribution. No code integration, installation, package replacement, other-tweak modification, phone test, source-build verification or runtime compatibility result is claimed for this discovery.
