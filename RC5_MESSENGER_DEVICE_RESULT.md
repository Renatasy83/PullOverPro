# RC5 Messenger device result: one background-marked observation

The supplied messenger-1.0.4.json reports version1.0.4~rc5 and exactly one observation. No raw device report is committed.

| Field | Observed value |
| --- | --- |
| State | observed |
| Enumerated scenes | 6 |
| Matched scenes | 1 |
| Exact normal application specification | true |
| Normal application role | true |
| Four expected framework UUIDs | all match |
| Layer probe | sampled |
| Layer count/types | 0 / empty |
| Source settings backgrounded | true |
| FBScene active | true |
| Hosting/mutation requested | false / false |

The read-only path executed and produced a report with a unique identity-bound normal specification/role source. This is useful real-device evidence for the observation component; it is not evidence of Messenger independent-window admission, visible pixels/input, app delegate behavior or general Dopamine/ElleKit compatibility. The active flag must not be equated with foreground UI. Zero layers in one background-marked sample does not prove permanent inability to render. No caller timing or user-confirmed foreground sample is present.

The next necessary test uses the already installed RC5: open Messenger normally, leave it visibly full-screen and attempt Messenger from PPO once, observing the two-second cooldown. Share the same report again; it retains the latest two observations. No reinstall/respring/new candidate, app killing, bundle edit, Data-container collection or other-app regression test is required for that comparison. A diagnostic refusal with no new window is expected.

The previous missing handle cause remains unknown: this file shows that the diagnostic path ran, not how the handle was restored or whether the disable marker was changed. Phone slowdown remains user-reported and unassigned to a proven cause.

Runtime source ca1c56ba1937a815f8762552685ceb0c18b83c7b and archived RC5 remain unchanged; prior Actions41578881921 passed35 suites, Clang analysis, rootless Theos build and package inspection. No new runtime change or test is represented by this documentation-only update.
