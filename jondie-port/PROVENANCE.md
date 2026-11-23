# PullOver Pro stability derivative

Original: c1d3r / Will Smillie. Rootless port: Jond_ie.

This source directory was imported without its Git metadata from:
https://github.com/Jond-ie/pulloverpro
Upstream revision: 076da8f07e707453bc58ed9baadeefb40f0e93e4.

Licence: GPL-3.0, see LICENSE. The upstream README and CHANGELOG remain supplied.
The derivative source and corrections are published in:
https://github.com/Renatasy83/PullOverPro/tree/improve/jondie-stability/jondie-port

This is an independently maintained candidate, not an official Jond_ie release.
Its version is 3.0.2~rc1 and its Debian package ID remains
com.johndie.pulloverpro-rootless so it upgrades that implementation and preserves
its preference domain. The original upstream package and source remain available
from https://jond-ie.github.io/repo/ and the upstream repository.

Modifications made on 2026-11-23.

The implemented corrections are keyboard geometry, bounded/cancellable startup,
rollback of partial hosting setup, QuickSwitch selection/layout guards and
preference validation. It preserves the original drawer interface and introduces
no new private SpringBoard API signatures. Read the validation report accompanying
the build for the actual checks run and remaining phone-only checks.

Build success, fake-interface tests and static analysis do not confirm app contents,
interaction, launch permissions or Dopamine/ElleKit runtime compatibility. There
are no maintainer scripts, automatic installations or automatic respring actions
in this package. The separate older diagnostic tweak must not be injected at the
same time, so the package declares a conflict with it; package removal/installation
is a manual user action. No personal data or preference files are deleted.
