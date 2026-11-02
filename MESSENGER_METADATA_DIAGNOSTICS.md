# Messenger: bounded negative diagnostics

Investigation source: d0303bd039aefe08817702fb737c85eae90336eb, branch debug/two-stage-handle-messages. This is not a new delivered package and does not fix Messenger hosting.

## Evidence

The RC4 phone report binds the refused attempt to com.facebook.Messenger, status unknown, reason manifest-unknown, eligible=false. No Messenger host session was created. The user confirms Messages works with com.apple.MobileSMS, after correcting the previously selected compose-helper identifier. Messages does not require another ordinary test.

The installed Messenger version and scene manifest are not available. The old report cannot distinguish missing declarations, invalid types, or earlier generic metadata failures. It does not prove an explicit multiple-scene prohibition or a rendering defect.

## Scoped change

| Metadata observed after earlier validation | New negative reason |
| --- | --- |
| UIApplicationSceneManifest absent | scene-manifest-missing |
| Manifest present with a non-dictionary type | scene-manifest-invalid |
| UIApplicationSupportsMultipleScenes absent | multiple-scenes-undeclared |
| Declaration present but not a CFBoolean | multiple-scenes-invalid |

All four results retain unknown status and eligible=false. A genuine false Boolean remains ineligible/multiple-scenes-disabled; true declarations still undergo all existing configuration and app checks. Eligibility branches, positive proof policy, seven-field wire structure, bundle reader, private methods, hosting and cleanup are unchanged. An older consumer rejects an unfamiliar negative reason rather than treating it as eligible. No raw plist, application contents, paths or new personal information enters reports.

Tests cover the existing malformed/missing metadata cases, every bounded unknown reason's JSON normalization, and refusal to reclassify those reasons as eligible or ineligible. Local source-policy and scoped-diff checks passed. GitHub Actions run41521971944/job125540017169 succeeded: all34 suites,3191 scene capability checks, native ASan/UBSan fixtures, Clang analysis, pinned Theos rootless arm64/arm64e build and payload/binary inspection. Artifact13179350959 (ZIP digest5298eb38214cba92da27953bbf01209cc265e7971c836a5e5f53be42ba84c535) is investigation evidence, not a new delivered release. No Messenger/iOS runtime test was executed; compilation establishes no phone compatibility. The original permanent RC4 package remains unchanged.

## Necessary missing input

Obtain the installed Messenger application's Info.plist from its .app bundle using Filza. Do not obtain the Data container or conversations, change the plist, or reinstall/respring merely for this collection. Bundle metadata is needed because no connected phone or matching installed app bundle is accessible in the development environment. This avoids asking for another diagnostic DEB installation only to identify the metadata shape.

After inspecting the exact identifier, version, device families, scene manifest and relevant top-level scene/window declarations, decide whether a documented, independently audited hosting path applies. Do not authorize unknown apps, borrow the Messages profile, guess flags or disable owner/admission/ABI checks. The permanent delivered RC4 archive, main and stable/recovery refs remain unchanged.
