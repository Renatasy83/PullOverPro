"""Source policy and Debian payload checks; these do not prove runtime safety."""
from pathlib import Path, PurePosixPath
import io
import plistlib
import re
import subprocess
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise SystemExit(message)


source = '\n'.join((ROOT / path).read_text() for path in ['Tweak.xm', 'PPOAppData.mm', 'PPOBridgeClient.mm', 'PPOBridgeProtocol.mm', 'PPOBridgeIO.cpp', 'PPOHostSessionSlot.mm'])
for pattern in (r'%hook\b', r'%init\b', r'objc_msgSend', r'NSClassFromString',
                r'NSSelectorFromString', r'valueForKey:', r'launchApplication',
                r'method_getImplementation', r'method_invoke', r'dlopen', r'dlsym',
                r'\bsystem\s*\(', r'\bpopen\s*\(', r'\bfork\s*\(', r'\bkill\s*\(',
                r'performSelector', r'NSInvocation', r'dispatch_sync', r'dispatch_semaphore_wait', r'\bsleep\s*\('):
    require(not re.search(pattern, source), f'Unexpected runtime operation: {pattern}')
scene_source = (ROOT / 'PPOScenePreflight.mm').read_text()
require(scene_source.count('objc_msgSend') == 2, 'Unexpected scene dispatch surface')
scene_getters = set(re.findall(r'PPOSceneGet\([^\n]*?"(\w+)"', scene_source))
require(scene_getters == {'sharedInstance', 'clientHandle', 'bundleIdentifier',
                         'definition', 'clientIdentity', 'identifier'},
        'Unexpected private scene accessor')
for pattern in (r'%hook\b', r'%init\b', r'valueForKey:', r'method_getImplementation',
                r'method_invoke', r'dlopen', r'dlsym', r'performSelector',
                r'dispatch_sync', r'dispatch_semaphore_wait', r'\bsleep\s*\('):
    require(not re.search(pattern, scene_source), f'Unexpected scene operation: {pattern}')
probe_source = (ROOT / 'PPOSceneLayerProbe.mm').read_text()
require(probe_source.count('objc_msgSend') == 1, 'Unexpected layer probe dispatch surface')
require(set(re.findall(r'ProbeGet<[^>]+>\([^\n]*?"(\w+)"', probe_source)) ==
        {'layerManager', 'settings', 'layers', 'type', 'isActive', 'isBackgrounded'},
        'Unexpected layer probe accessor')
for pattern in (r'valueForKey:', r'object_getIvar', r'method_getImplementation',
                r'performSelector', r'NSInvocation', r'setForeground:', r'updateSettings',
                r'contextID', r'renderID', r'dispatch_sync', r'\bsleep\s*\('):
    require(not re.search(pattern, probe_source), f'Unexpected layer probe operation: {pattern}')
require('count > 32' in probe_source and 'NSThread.isMainThread' in probe_source and
        'class_copyMethodList' in probe_source, 'Layer probe bounds and dispatch guards required')
presenter_source = (ROOT / 'PPOScenePresenter.mm').read_text()
require(presenter_source.count('objc_msgSend') == 6, 'Unexpected presenter dispatch surface')
require(set(re.findall(r'PPOObject\([^\n]*?"(\w+)"', presenter_source)) ==
        {'uiPresentationManager', 'identifier', 'presentationView', 'presentationContext'}, 'Unexpected presenter getter')
require(set(re.findall(r'PPOTell\([^\n]*?"(\w+)"', presenter_source)) ==
        {'activate', 'invalidate'}, 'Unexpected presenter mutation')
require(set(re.findall(r'PPOFlag\([^\n]*?"(\w+)"', presenter_source)) ==
        {'isInvalidated', 'isActive', 'isHosting', '_isVisibilityPropagationEnabled'}, 'Unexpected presenter state getter')
trial_source = (ROOT / 'PPOFloatingTrial.mm').read_text()
for pattern in (r'%hook\b', r'%init\b', r'valueForKey:', r'method_getImplementation',
                r'method_invoke', r'dlopen', r'dlsym', r'performSelector',
                r'dispatch_sync', r'dispatch_semaphore_wait', r'\bsleep\s*\(',
                r'setForeground:', r'updateSettings', r'modifyDefaultPresentationContext',
                r'createPresenterWithIdentifier:priority:', r'object_getIvar',
                r'makeKeyWindow', r'makeKeyAndVisible', r'becomeFirstResponder',
                r'BKSHID', r'IOHID', r'GS\w*Event'):
    require(not re.search(pattern, presenter_source + trial_source),
            f'Unexpected hosting operation: {pattern}')
require('modifyPresentationContext' not in trial_source,
        'Private context mutation belongs only in the owned-presenter adapter')
require('"modifyPresentationContext:", "@?"' in presenter_source and
        '"_setVisibilityPropagationEnabled:", @encode(bool)' in presenter_source and
        'context == original' in presenter_source and 'callbacks != 1' in presenter_source and
        '!accepting' in presenter_source, 'Own-context callback shape and ownership guards required')
require('setHostedSecureApp' not in presenter_source + trial_source and
        'setPresentedLayerTypes' not in presenter_source + trial_source,
        'No shared scene/security or guessed layer-mask writes')
require('objc_msgSend' not in trial_source, 'UIKit trial must not dispatch private APIs')
require('self.content.userInteractionEnabled = NO' in trial_source,
        'Preserve the container flag used in the observed device trial')
require('toggleInput:' not in trial_source and 'inputButton' not in trial_source,
        'Remove the misleading remote input switch')
for obsolete in ('@"inputEnabled"', '@"inputEverEnabled"', 'Atingeri: oprite', 'Atingeri: pornite'):
    require(obsolete not in trial_source, f'Ambiguous input claim: {obsolete}')
require('@"containerUserInteractionEnabled"' in trial_source and
        '@"inputBlockingGuaranteed": @NO' in trial_source and
        '@"inputRoutingMechanism": @"unconfirmed"' in trial_source,
        'Separate UIView flags from remote input guarantees')
for attribute in ('bounds', 'transform', 'center', 'frame'):
    require(not re.search(r'(?<![\w.])(?:view|presentation)\.' + attribute + r'\s*=(?!=)', trial_source),
            'Private presentation geometry must remain UIKit-owned')
require('self.scalingWrapper.transform = CGAffineTransformMakeScale' in trial_source and
        '@"layout-100ms"' in trial_source and '@"layout-750ms"' in trial_source,
        'Owned-wrapper layout and bounded observations are required')
owned_source = (ROOT / 'PPOOwnedSceneHost.mm').read_text()
owned_trial = (ROOT / 'PPOOwnedSafariTrial.mm').read_text()
for pattern in (r'valueForKey:', r'object_getIvar', r'method_getImplementation', r'performSelector',
                r'dlopen', r'dlsym', r'setForeground:', r'updateSettings', r'setHostedSecureApp',
                r'dispatch_sync', r'dispatch_semaphore_wait', r'\bsleep\s*\(',
                r'foregroundAssertionForReason:', r'createSceneWithDefinition:'):
    require(not re.search(pattern, owned_source + owned_trial), f'Unexpected separate-scene operation: {pattern}')
require(owned_source.count('objc_msgSend') == 4, 'Unexpected separate-scene dispatch surface')
require('object_getClass(componentScene) == HostClass(self.classes, @"FBSComponentScene")' in owned_source and
        'else if (proxyClassMatches)' in owned_source and
        'boundScene = HostObject(componentScene, "scene")' in owned_source and
        'if (boundScene != child)' in owned_source,
        'Only the exact known component proxy may unwrap to the owned scene')
require('@"componentBinding": self.componentBinding' in owned_source and
        'HostObject' not in owned_source.split('- (NSDictionary *)snapshot {', 1)[1],
        'Binding diagnostics must not invoke private getters during snapshot')
require(set(re.findall(r'HostSet\([^\n]*?"(\w+:)"', owned_source)) ==
        {'setSceneWorkspace:', 'setSceneIdentifier:', 'setSceneSpecification:'},
        'Separate-scene setters must only configure owned constructor input')
require(set(re.findall(r'HostTell\([^\n]*?"(\w+)"', owned_source)) == {'invalidate'},
        'Separate-scene operations must only invalidate verified own objects')
require('objc_msgSend' not in owned_trial and 'initWithClasses:classes' in owned_trial,
        'Separate-scene UI must delegate private operations to ownership adapter')
require('[bundleIdentifier isEqual:@"com.apple.mobilesafari"]' in owned_trial,
        'Only firmware-manifest-verified Safari may create a separate scene')
require('childView.frame =' in owned_trial and
        owned_trial.index('childView.frame =') < owned_trial.index('[root addChildViewController:child]'),
        'Provide public native child geometry before attachment/appearance')
require('self.cleanupPolls >= 8' in owned_trial and 'NSEC_PER_SEC / 4' in owned_trial and
        'self.deadline = NSProcessInfo.processInfo.systemUptime + 15' in owned_trial,
        'Bounded trial and asynchronous cleanup required')
production_sources = (ROOT / 'Makefile').read_text()
require('PPOOwnedSceneHost.mm PPOOwnedSafariTrial.mm' in production_sources and
        'PPOFloatingTrial.mm' not in production_sources,
        'Production must use the separate-scene adapter without borrowed-scene fallback')
slot_source = (ROOT / 'PPOHostSessionSlot.mm').read_text()
require('self.session.finished' in slot_source and 'self.session.replacementAllowed' in slot_source and
        'self.poisoned = YES' in slot_source, 'Session replacement must fail closed')
require('static BOOL attempted' not in (ROOT / 'Tweak.xm').read_text(),
        'Replace per-process trial block with owned session gate')
require('!self.running && !self.closing' in trial_source,
        'Session must remain busy until synchronous cleanup returns')
require('PPOHostApplicationAllowed(bundleIdentifier)' in trial_source,
        'Floating session target policy missing')
require('@"com.apple.mobilesafari"' in slot_source and '@"com.apple.Preferences"' in slot_source,
        'Unexpected controlled hosting targets')
require('THEOS_PACKAGE_SCHEME := rootless' in (ROOT / 'Makefile').read_text(),
        'Rootless scheme missing')
filter_path = ROOT / 'PullOverProDiagnostic.plist'
expected_filter = '{Filter={Bundles=("com.apple.springboard");};}'
require(re.sub(r'\s+', '', filter_path.read_text()) == expected_filter,
        'Injection must target SpringBoard only')
duplicate = ROOT / 'layout/Library/MobileSubstrate/DynamicLibraries/PullOverProDiagnostic.plist'
require(not duplicate.exists(), 'Duplicate injection filter in layout')
print('Source policy OK (not a runtime test)')

for arg in sys.argv[1:]:
    deb = Path(arg)
    def field(name):
        return subprocess.check_output(['dpkg-deb', '-f', str(deb), name], text=True).strip()
    require(field('Package') == 'com.renatasy83.pulloverpro.diagnostic', 'Unexpected package')
    require(field('Architecture') == 'iphoneos-arm64', 'Unexpected architecture')
    require(field('Version').startswith('0.9.1~dev.componentproxy1'), 'Unexpected version')
    require('ellekit' in field('Depends'), 'ElleKit dependency missing')
    require('bash' in field('Depends'), 'Lifecycle script interpreter dependency missing')
    payload = subprocess.check_output(['dpkg-deb', '--fsys-tarfile', str(deb)])
    base = 'var/jb/Library/MobileSubstrate/DynamicLibraries/'
    required = {base + 'PullOverProDiagnostic.dylib', base + 'PullOverProDiagnostic.plist',
                'var/jb/usr/bin/ppo-apps', 'var/jb/usr/bin/ppo-open', 'var/jb/usr/bin/ppo-bridge',
                'var/jb/Library/LaunchDaemons/com.renatasy83.ppo.bridge.plist',
                'var/jb/usr/share/doc/com.renatasy83.pulloverpro.diagnostic/copyright'}
    found = set()
    with tarfile.open(fileobj=io.BytesIO(payload)) as archive:
        for member in archive:
            name = member.name.removeprefix('./')
            require('..' not in PurePosixPath(name).parts and not name.startswith('/'),
                    f'Unsafe archive path: {name}')
            if member.isdir():
                continue
            require(member.isfile() and name in required, f'Unexpected payload: {name}')
            require(name not in found, f'Duplicate payload: {name}')
            if name in {'var/jb/usr/bin/ppo-apps', 'var/jb/usr/bin/ppo-open', 'var/jb/usr/bin/ppo-bridge'}:
                require(member.mode & 0o111, 'Helper is not executable')
            found.add(name)
            if name.endswith('copyright'):
                require(archive.extractfile(member).read() == (ROOT / 'layout/usr/share/doc/com.renatasy83.pulloverpro.diagnostic/copyright').read_bytes(), 'License/attribution mismatch')
            if name.endswith('.dylib') or name == 'var/jb/usr/bin/ppo-bridge':
                require(b'PPO_BRIDGE_TEST_PATH' not in archive.extractfile(member).read(), 'Test path override leaked into release binary')
            if name.endswith('com.renatasy83.ppo.bridge.plist'):
                raw = archive.extractfile(member).read()
                require(plistlib.loads(raw) == plistlib.loads((ROOT / 'layout/Library/LaunchDaemons/com.renatasy83.ppo.bridge.plist').read_bytes()), 'Bridge service plist mismatch')
            elif name.endswith('.plist'):
                raw = archive.extractfile(member).read()
                if raw.startswith(b'bplist') or raw.lstrip().startswith(b'<?xml'):
                    require(plistlib.loads(raw) == {'Filter': {'Bundles': ['com.apple.springboard']}},
                            'Packaged binary/XML filter mismatch')
                else:
                    require(re.sub(r'\s+', '', raw.decode()) == expected_filter,
                            'Packaged OpenStep filter mismatch')
    require(found == required, f'Missing payload: {required - found}')
    metadata = subprocess.check_output(['dpkg-deb', '--ctrl-tarfile', str(deb)])
    control_found = set()
    with tarfile.open(fileobj=io.BytesIO(metadata)) as archive:
        for member in archive:
            if member.isdir():
                continue
            name = member.name.removeprefix('./')
            require(member.isfile() and name in {'control', 'md5sums', 'postinst', 'prerm'},
                    f'Unexpected maintainer script or metadata: {name}')
            control_found.add(name)
            if name in {'postinst', 'prerm'}:
                require(member.mode & 0o111, 'Nonexecutable service lifecycle script')
                require(archive.extractfile(member).read() == (ROOT / 'layout/DEBIAN' / name).read_bytes(), 'Service lifecycle script mismatch')
    require({'control', 'postinst', 'prerm'} <= control_found, 'Missing service lifecycle scripts')
    print(f'Rootless payload OK: {deb.name} (not a runtime test)')

