# Isolated launch bridge — development only

The device report shows EPERM from access(X_OK) and posix_spawn in SpringBoard, while the same helper opens Safari from NewTerm. The enforcement mechanism remains unknown. This implementation removes process creation from SpringBoard instead of changing permissions, credentials or injection settings.

The Debian package adds only its own launchd service, `com.renatasy83.ppo.bridge`, running as mobile:mobile. Its postinst bootstraps that service and its prerm stops that service. No automatic respring, other service changes, root execution of app APIs, added entitlements, app termination or deletion of user files occurs. Installing the package changes service lifecycle; building it does not install anything on the phone. The service stops when the package is removed; its small data files are retained.

The overlay sends one request at a time on its serial worker queue. No private calls or process creation happen in SpringBoard. The app list refresh also uses the service, removing the need to run ppo-apps manually. App identifiers are matched exactly against a fresh, validated inventory before launch. Inventory presence does not prove launchability. An accepted reply means LaunchServices accepted the request; it is not a visual confirmation.

Mailbox: `/var/mobile/Library/Logs/PullOverPro/Bridge`, mobile-owned mode0700, fixed files mode0600, maximum4096 bytes. The transport rejects symlink endpoints, hardlinks, FIFOs, incorrect ownership/modes and oversized content. Atomic replacement avoids partial JSON. Existing files are never chmodded. Intermediate path components are within mobile's own hierarchy; this is not an isolation boundary against arbitrary malicious code already running as mobile. Other mobile processes have the same authority as mobile preferences.

Requests have a UUID, explicit operation and five-second monotonic lifetime. Replies must match the UUID. The service rechecks launch expiry after enumeration. The service ignores any request present at its startup; pending requests are never automatically retried across service restarts. The UI stops launch requests after a missing/unknown response until respring. A crash between acceptance and response can leave an unknown result; exactly-once completion is not promised. There is no automatic retry of launches.

The service uses directory kqueue events rather than idle polling. A per-service alarm bounds private API stalls to20s; launchd throttles restarts to30s. This cannot freeze SpringBoard's UI thread. The client observes for at most8s on a worker and reports unknown result if necessary. A syscall blocked inside the kernel cannot be bounded solely by user-space timers.

The service supports ordinary app launch requests, not scene creation or hosting. It refuses SpringBoard and backboardd explicitly. Runtime ABI guards are inherited from the device-inspected getter/opener signatures. They do not establish permissions or correct lifecycle in the new launchd context. No successful integration test of that context is available.

## Automated checks

- Portable actual-filesystem transport tests, including concurrent readers/replacement and malformed filesystem entries; ASan/UBSan on Linux and macOS CI.
- Native Foundation protocol tests: malformed/type-confused/oversized JSON, TTL, UUID binding and strict operations.
- Native service policy tests with a fake workspace: membership, restricted targets, expiry during enumeration, exception containment, main-thread enforcement and report persistence.
- Existing data/ABI/process-wrapper regressions remain in CI; the old process wrapper is not linked into the tweak.
- Clang analysis and Theos rootless arm64/arm64e build plus payload and service-lifecycle inspection.

Not executed here: launchd bootstrap on iOS, SpringBoard sandbox file IPC, LaunchServices in daemon context, visual app launch, rendering/touch/keyboard hosting, lock/orientation transitions, watchdog and Dopamine/ElleKit injection integration. Mocks and compilation cannot replace these tests.
