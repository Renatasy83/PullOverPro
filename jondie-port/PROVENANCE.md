# PullOver Pro window size derivative

Original: c1d3r / Will Smillie. Rootless port: Jond_ie.

This source directory was imported without its Git metadata from:
https://github.com/Jond-ie/pulloverpro
Upstream revision: 076da8f07e707453bc58ed9baadeefb40f0e93e4.

Licence: GPL-3.0, see LICENSE. The upstream README and CHANGELOG remain supplied.
The derivative source and corrections are published in:
https://github.com/Renatasy83/PullOverPro/tree/feature/jondie-window-size/jondie-port

This is an independently maintained candidate, not an official Jond_ie release.
Its version is 3.0.2~rc2 and its Debian package ID remains
com.johndie.pulloverpro-rootless so it upgrades that implementation and preserves
its preference domain. The original upstream package and source remain available
from https://jond-ie.github.io/repo/ and the upstream repository.

Stability modifications made on 2026-11-23: keyboard geometry,
bounded/cancellable startup, rollback of partial hosting setup, QuickSwitch
selection/layout guards and preference validation. The user subsequently reported
that candidate 3.0.2~rc1 works on their previously stated device setup. That report
does not establish all applications, prolonged stability or measured performance.
The preserved RC1 source is 22adc654e237d21d26a67535a994f63c4980b4bd; its DEB and
validation evidence remain in archive 6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463
and checkpoint/user-reported-working-jondie-3.0.2-rc1.

Window size modifications made on 2026-11-24: aspect-preserving window
redimensioning and remembered size for each selected application. RC2 preserves
the original edge drawer interface and existing private API contracts. No new
private SpringBoard API signatures are introduced. This new candidate and its
resizing/touch behavior have not yet been verified on the user's phone. Read the
validation report accompanying the build for checks actually executed and the
remaining device-only checks.

Build success, fake-interface tests and static analysis do not confirm app
contents, interaction, launch permissions or Dopamine/ElleKit runtime
compatibility. Embedded ldid CodeDirectory checks establish internal hash
integrity, not Apple certificate authenticity or jailbreak device acceptance.
The actual macOS codesign diagnostic is retained separately from that integrity
check. There are no maintainer scripts, automatic installations or automatic
respring actions in this package. The separate older diagnostic tweak must not
be injected at the same time, so the package declares a conflict with it;
package removal/installation is a manual user action. No personal data or
preference files are deleted.
