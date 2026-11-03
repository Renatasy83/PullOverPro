# RC5 mailbox evidence

The supplied request is inspect-scene for com.facebook.Messenger, createdUptime238.09916733333336. The supplied response is an inspected/missing-manifest reply for Messenger but its nonce differs; its uptime269064.2314720417 cannot be treated as a result for that request. The startup heartbeat is ready/service-ready at uptime267.1975894166667. Raw nonces and user JSON are not published.

The paired capability timeout timestamp246.19693858333335 minus request creation is8.09777125seconds, consistent with the configured8second client limit. Heartbeat minus request is29.09842208seconds; minus capability error is21.00065083seconds. These differences describe a timeline only if the monotonic values share a boot. Mailbox files survive restart and lack a boot/service-instance identifier, so service startup after this request, an old response from a previous boot, current service liveness and an alarm-triggered restart are not confirmed solely by the files.

The client is correct not to accept a different nonce. Startup suppression of preexisting requests is a safety invariant, not something to remove to make a retry work. A20second service alarm and launchd KeepAlive exist in source; launchd status/exit evidence is needed before attributing failure to them or a blocked private call.

Next read-only diagnostic: /var/jb/usr/bin/launchctl print system/com.renatasy83.ppo.bridge. Preserve state and exit/termination information before restarting anything. Do not start another --serve process or repeat Messenger foreground tests until that state is read. No new runtime changes/tests/builds are represented by this document. Previous RC5 automated/phone evidence remains scoped as recorded in OPENCODE_HANDOFF.md.
