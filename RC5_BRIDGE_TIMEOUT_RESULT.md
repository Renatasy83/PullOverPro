# RC5 bridge timeout evidence

The supplied capability report identifies com.facebook.Messenger, version1.0.4~rc5. It records response-unavailable/unavailable, null scene capability, errorCode60 and observedUptime246.19693858333335. The target Darwin errno60 is ETIMEDOUT. The production client records POSIX errors and waits up to8seconds for a valid response with the current nonce; absence, malformed replies or wrong-nonce replies can end in this timeout. It is not evidence of scene incompatibility, a SpringBoard crash or a proven service-side cause.

This failure occurs before the Messenger observer, so the foreground source comparison has not been obtained. The existing single background-marked Messenger scene report is not contradicted by an independent later transport failure. No continuity of service process or boot session is inferred from these files.

Next inspect only existing request.json, response.json and heartbeat.json in /var/mobile/Library/Logs/PullOverPro/Bridge/. Preserve them before retrying/restarting so request/response nonce, operation and monotonic timestamps can be compared. A heartbeat is startup-only, not an ongoing health check; a stale response must not be accepted or replayed. The service intentionally ignores requests present at startup. Native subprocess tests cover restart no-replay and wrong-nonce client timeout, but do not establish this phone's failure cause.

No code changes, timeout extension, automatic retry, phone action or new build were performed for this report. The raw user report is not published. See OPENCODE_HANDOFF.md for current source/archive/test evidence and next steps.
