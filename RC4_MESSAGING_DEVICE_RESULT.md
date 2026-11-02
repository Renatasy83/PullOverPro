# RC4 device result: messaging refusals

The latest capability-1.0.3.json contains inspected, canonical policy-v4 unknown/manifest-unknown results for:
- com.facebook.Messenger
- com.apple.mobilesms.compose

There is NO observation for com.apple.MobileSMS, the exact Messages identifier covered by the new firmware profile. Do not interpret the compose selection as a failed test of that profile, and do not alias compose to MobileSMS or bypass identity checks.

The host report contains three successful source-free sessions for Files, Safari and Calendar, with layers and clean closed/unpinned/unpoisoned teardown. Neither messaging identifier reached scene creation. Their observed failure is pre-host eligibility refusal, not a demonstrated rendering/activation exception.

Interface trace has reveal events without incrementing inspection/window-attempt counts, followed by separate explicit inspections; final counters are8reveals,5inspections,3window attempts. This supports command separation but is not a complete physical UX/input confirmation.

Next minimal check on the existing RC4: select the real Messages entry com.apple.MobileSMS. A picker identity/display ambiguity may need correction; current short row labels do not expose full bundle IDs. Do not ask for another installation merely to repeat this check.

Messenger remains unresolved. manifest-unknown is a coarse classification: it does NOT establish explicit multiple-scenes=false or that the app can never be hosted. Obtain its bounded installed manifest structure/version before choosing a route; do not remove guards blindly. Current reports do not carry that structure.

No new runtime code or package is implied by recording this result. Raw phone reports/app content are not published. Keep main and scoped stable RC2 unchanged.
