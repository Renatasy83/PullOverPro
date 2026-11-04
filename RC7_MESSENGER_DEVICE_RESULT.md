# RC7 Messenger observation: return refused on old-root condition

The user supplied `host-1.0.6.json` without a new visual outcome description. No raw report, conversation content or application data is published here.

The report retains three sessions: unavailable companion, stale captured readiness, then a timed Messenger trial. The final helper uses schema1: phase4, flags147, sampled uptime31273, readiness false. In RC7 flags147 mean captured1 + owned-scope-seen2 + old-root-condition16 + refused128. Accepted migration4 and return-readback8 are absent.

RC7 sets bit16 after observing the exact captured UIWindow in a distinct identified PPO session, when its previous weak root is missing or different. Thus the observation supports injection, state transport, PPO public-session recognition and that old-root refusal. It does not distinguish root replacement from release and does not prove that the full-screen UI recovered or remained black.

The timed window was shown at31256.693731583335 and closed at31271.73473904167, about15.041seconds later, with timeout as close reason. The owner reports a verified distinct child/proxy, original source provided, own controller/workspace invalidation returned, closed/unpinned/unpoisoned, and replacement allowed. The final original-scene sample at31271.219669 precedes closure. Post-close helper observations are separate state metadata; they do not establish pixels or input delivery.

RC6 already had user-confirmed Messenger small-window content, touch and scrolling, together with a black original surface during and after closure. RC7's supplied metadata adds the old-root refusal evidence, not a new visual confirmation.

RC8 keeps exact original UIWindow identity and validates its current root's public UIKit ownership. It does not assign an old root or reparent another controller/view. Schema2/channelv2 avoid confusing the new observed-root-replacement flag with RC7's refusal flag. Automated policy tests cover this change; actual original-window return still needs one scoped phone test after a fully validated DEB exists. See `RC8_MESSENGER_CURRENT_ROOT_RETURN.md`.
