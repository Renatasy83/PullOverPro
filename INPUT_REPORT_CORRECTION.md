# Input report correction — 0.7.3

The user observed Safari scrolling inside the small window while0.7.2 displayed "Atingeri: oprite". The report agrees that the UIView flag was never enabled and that automatic timeout invalidation completed after about15.03 seconds.

The defect corrected here is the categorical UI/report claim. The old inputEnabled field described one UIView property. It did not measure delivery to Safari and did not establish a remote-input blocking mechanism. Direct routing to the hosted surface, events reaching Safari underneath, and other WindowServer behavior are not distinguished by the evidence supplied. No cause is asserted without a discriminating observation.

0.7.3 removes the input switch and restores the simpler Safari ·15s/X header. It keeps the same container userInteractionEnabled=NO setting used in the observed0.7.2 trial. No presenter creation, activation, teardown, event-deferral, foreground setting or key-window behavior changes are introduced. This is a UI/telemetry correction, not a fix that blocks remote touches.

Report schema2 (host-0.7.3.json) uses containerUserInteractionEnabled and presentationViewUserInteractionEnabled for literal property values; inputBlockingGuaranteed=false and inputRoutingMechanism=unconfirmed state the actual limits. No URL, typed text, touch coordinates or app content are collected. The presenter state and close reason remain reported.

Known evidence remains separate: user-confirmed live Safari rendering and manual X-close on0.7.1; user-observed scrolling with the switch off and report-confirmed automatic timeout cleanup on0.7.2. Keyboard focus, isolated hosted-surface input, lock/orientation/process death and complete Dopamine/ElleKit compatibility are unconfirmed.

No phone installation is requested merely to check removal of a misleading label. CI must still pass source policy, Clang analysis, existing native/sanitizer fixtures, Theos rootless arm64/arm64e compilation and payload/license/lifecycle inspection. These do not test WindowServer input routing.

The working source is preserved on stable/verified-safari-rendering and stable/verified-safari-timeout. Existing recovery remains: responsive phone — create /var/mobile/.ppo_disable; unresponsive SpringBoard — force restart, enable Dopamine without tweak injection, uninstall only com.renatasy83.pulloverpro.diagnostic. No automatic phone action or personal-data deletion occurs.
