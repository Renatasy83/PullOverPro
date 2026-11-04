"""Source policy and Debian payload checks; these do not prove runtime safety."""
from pathlib import Path, PurePosixPath
import io
import json
import plistlib
import re
import subprocess
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise SystemExit(message)


source = '\n'.join((ROOT / path).read_text() for path in ['Tweak.xm', 'PPOCapabilityDiagnostics.mm', 'PPOKeyboardMonitor.mm', 'PPOClassicQuickSwitchView.mm', 'PPOAppData.mm', 'PPOBridgeClient.mm', 'PPOBridgeProtocol.mm', 'PPOBridgeIO.cpp', 'PPOHostSessionSlot.mm', 'PPOFavoriteApps.mm', 'PPOFavoritesStore.mm', 'PPOPickerState.mm'])
for pattern in (r'%hook\b', r'%init\b', r'objc_msgSend', r'NSClassFromString',
                r'NSSelectorFromString', r'valueForKey:', r'launchApplication',
                r'method_getImplementation', r'method_invoke', r'dlopen', r'dlsym',
                r'\bsystem\s*\(', r'\bpopen\s*\(', r'\bfork\s*\(', r'\bkill\s*\(',
                r'performSelector', r'NSInvocation', r'dispatch_sync', r'dispatch_semaphore_wait', r'\bsleep\s*\('):
    require(not re.search(pattern, source), f'Unexpected runtime operation: {pattern}')
observation_source = (ROOT / 'PPOSceneObservation.mm').read_text()
require(observation_source.count('objc_msgSend') == 1, 'Unexpected observation dispatch surface')
require(set(re.findall(r'ObservationGet\([^\n]*?"(\w+)"', observation_source)) ==
        {'definition', 'specification', 'uiSceneSessionRole'}, 'Unexpected observation accessor')
for token in ['activate', 'createPresenter', 'updateSettings', 'setForeground', 'setBackgrounded',
              'createScene', 'invalidate', 'performSelector', 'NSInvocation', 'method_getImplementation']:
    require(token not in observation_source, 'Unexpected mutating observation operation: ' + token)
picker_source = (ROOT / 'Tweak.xm').read_text()
require('PPOPickerState *picker' in picker_source and
        'return self.picker.selectionGeneration' in picker_source and
        'sender.boundGeneration != self.renderGeneration' in picker_source and
        'PPOPickerRowButton new' in picker_source,
        'Picker must own transaction generations and immutable row identity')
require('PPOFavoritesLoad(PPOFavoritesDirectory' in picker_source and
        'PPOFavoritesCommit(PPOFavoritesDirectory' in picker_source and
        'ticket.expectedFavorites, ticket.replacementFavorites' in picker_source and
        'quickFavorites:' in picker_source,
        'Favorite storage and quick selection must use explicit worker transactions')
require('makeKeyAndVisible' not in picker_source and 'becomeFirstResponder' not in picker_source,
        'Favorites must preserve existing key-window and keyboard focus behavior')
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
return_agent = (ROOT / 'PPOMessengerReturnAgent.mm').read_text()
for token in ['objc_msgSend', 'NSSelectorFromString', 'NSClassFromString', 'method_getImplementation',
              'performSelector', 'makeKeyAndVisible', 'makeKeyWindow', 'becomeFirstResponder',
              '%hook', 'setForeground', 'updateSettings', 'writeToFile', 'snapshotView', 'UIGraphics', 'setRootViewController:']:
    require(token not in return_agent, 'Unexpected Messenger agent operation: ' + token)
require(not re.search(r'\.rootViewController\s*=(?!=)', return_agent), 'Agent must not assign a root controller')
require('window.windowScene=target' in return_agent and 'CurrentRootOwned(window)' in return_agent and 'window==_handoffWindow' in return_agent and
        'com.renatasy83.ppo.scene.' in return_agent and 'CC_SHA256' in return_agent,
        'App-side restoration requires exact original window/root, owned session and profile')
require(re.sub(r'\s+', '', (ROOT / 'PPOMessengerReturnAgent.plist').read_text()) ==
        '{Filter={Bundles=("com.facebook.Messenger");};}', 'Messenger companion must have its own exact app-only filter')
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
require('identityForBundleID:' in owned_source and 'unsupported-cold-input-abi' in owned_source and
        'cold-inputs-require-installed-eligibility' in owned_source and
        'object_getClass(self.factoryIdentity) != identityClass' in owned_source and
        'object_getClass(self.factorySpecification) != specificationClass' in owned_source and
        '@"sourceSceneProvided"' in owned_source and '@"fresh-application-identity"' in owned_source,
        'Cold constructor inputs require guarded factories, exact classes, eligibility and truthful absence telemetry')
require('!foreignScene && ![self.selection[@"state"] isEqual:@"not-found"]' in owned_trial and
        'startForApplicationIdentity' in owned_trial and 'conditions.renderReady' in owned_trial and
        '(!self.coldStart || _lifetime.observedRendered())' in owned_trial,
        'Cold fallback must refuse ambiguous sources and bound initial render before Keep')

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
require('PPOOwnedAdmissionSnapshot(self.bundleIdentifier, capability' in owned_trial and
        'forBundleIdentifier:self.bundleIdentifier' in owned_trial and
        'capability:self.sceneCapability' in owned_trial and
        'PPOOwnedAdmissionSnapshot(identifier, capability' in owned_source and
        owned_source.count('"bundleIdentifier"), self.expectedBundleIdentifier') == 2,
        'Selected identity must be independently checked against both source and owned child')
target_facts = json.loads((ROOT / 'SCENE_TARGETS_23A355.json').read_text())
policy_source = (ROOT / 'PPOOwnedApplicationPolicy.h').read_text()
target_ids = {app['bundleIdentifier'] for app in target_facts['applications']}
require(target_ids == {'com.apple.mobilesafari', 'com.apple.reminders', 'com.apple.MobileAddressBook'} and
        target_ids == set(re.findall(r'@"(com\.[^"]+)"', policy_source)),
        'Only the three selected exact-firmware targets may bypass selected-app inspection')
admission_source = (ROOT / 'PPOOwnedAdmission.mm').read_text()
capability_source = (ROOT / 'PPOSceneCapability.mm').read_text()
require('CapabilityMessagesProfile(raw, manifest)' in capability_source and
        'declared-messages-programmatic-scenes' in capability_source and
        '![raw[@"bundleIdentifier"] isEqual:@"com.apple.MobileSMS"]' in capability_source and
        '@"1448.100.1.2.102"' in capability_source and '@"SMSApplication"' in capability_source and
        'CapabilityBoolean(manifest[@"UIApplicationSupportsSceneItemProviders"])' in capability_source and
        '[manifest isEqual:expected]' in capability_source,
        'Messages advisory eligibility must retain the exact audited profile and identifier-bound reason')

bundle_reader = (ROOT / 'tools/bridge/PPOBundleSceneReader.mm').read_text()
require('PPOSceneCapabilityNormalize(capability)' in admission_source and
        'PPOSceneCapabilityFresh(observed, now)' in admission_source and
        '[observed[@"bundleIdentifier"] isEqual:selected]' in admission_source,
        'Dynamic admission must be copied, fresh and bound to the selected identifier')
require('object_getClass(specification)' in owned_source and 'object_getClass(childSpecification)' in owned_source,
        'Dynamic source and child specifications must reject unreviewed subclasses')
require('CFBooleanGetTypeID()' in capability_source and 'installed-basic-multiscene-v4' in capability_source and
        'observed + 5.0' in capability_source,
        'Capability policy must use explicit booleans and short-lived normalized metadata')
require(bundle_reader.count('objc_msgSend') == 1 and 'GetterOwner(object_getClass(proxy)' in bundle_reader and
        '0FFF723A-7DE6-3705-B327-ADD82FAEF345' in bundle_reader and
        'O_NOFOLLOW' in bundle_reader and 'openat(' in bundle_reader and '256 * 1024' in bundle_reader,
        'Only the verified cached bundleURL getter and bounded selected Info.plist may be read')
require('PPOBundleSceneReader.mm' not in (ROOT / 'Makefile').read_text() and
        'PPOBundleSceneReader.mm' in (ROOT / 'tools/bridge/Makefile').read_text(),
        'Bundle metadata file access must remain in the mobile helper')
require('PPOBridgeSend(@"inspect-scene", identifier' in (ROOT / 'Tweak.xm').read_text() and
        'epoch != self.saveEpoch' in (ROOT / 'Tweak.xm').read_text() and
        'kickstart -k system/com.renatasy83.ppo.bridge' in (ROOT / 'layout/DEBIAN/postinst').read_text(),
        'Selected inspection must remain asynchronous and upgrades restart only the own service')
require('(!response ||' not in (ROOT / 'Tweak.xm').read_text(),
        'Missing, malformed and wrong-nonce responses must not open baseline windows through timeout')
require(target_facts['firmware'] == {'productType': 'iPhone12,5', 'productVersion': '26.0.1', 'buildVersion': '23A355'} and
        target_facts['runtimeCompatibilityConfirmed'] is False and all(
            app['declaresMultipleScenes'] is True and 1 in app['deviceFamilies'] and
            len(app['applicationRoleConfigurations']) == 1 and
            re.fullmatch(r'[0-9a-f]{64}', app['infoSHA256']) for app in target_facts['applications']),
        'Target facts must remain explicit iPhone multiscene declarations, not runtime claims')
floating_policy = (ROOT / 'PPOFloatingWindowGeometry.h').read_text()
require('#include "PPOFloatingWindowGeometry.h"' in owned_trial and
        'PPOFloatingInitial(' in owned_trial and 'PPOFloatingResize(' in owned_trial and '_presentation.move(' in owned_trial,
        'Window placement must use the bounded public geometry policy')
require(owned_trial.count('childView.frame =') == 1 and
        'self.sizeButton = nil; self.closeButton = nil;' in owned_trial and
        '@"wrapperOnlyResize": @YES' in owned_trial,
        'Resize must preserve the single pre-containment native frame and clear own controls on cleanup')
require('PPOPlacementInsets(scene)' in owned_trial and
        'candidate.safeAreaInsets' in owned_trial and 'self.window.safeAreaInsets' not in owned_trial and
        'windows.count <= 128' in owned_trial,
        'Screen insets must be bounded and captured without moving-window feedback')
require('std::isfinite' in floating_policy and 'PPOFloatingMargin = 8' in floating_policy and
        'PPOFloatingMinWidth = 240' in floating_policy and 'PPOFloatingMinHeight = 320' in floating_policy,
        'Public geometry must retain finite bounds, reachable controls and minimum viewport size')
require('#include "PPOFloatingWindowPresentation.h"' in owned_trial and
        '_presentation.minimize(' in owned_trial and '_presentation.restore(' in owned_trial and
        '_presentation.stop();' in owned_trial and 'self.restoreButton = nil;' in owned_trial,
        'Minimize/restore must share the bounded terminal presentation policy and clear own controls')
require('UIAction actionWithTitle:' in owned_trial and '__weak PPOOwnedSafariTrial *weakSelf' in owned_trial and
        'showsMenuAsPrimaryAction = YES' in owned_trial,
        'Public action menus must use weak trial captures')
for action in ('minimizeFromButton', 'restoreFromButton'):
    body = re.search(r'- \(void\)' + action + r':\(UIButton \*\)sender \{(.*?)\n\}', owned_trial, re.S)
    require(body is not None and '[self checkLifetime]' in body.group(1) and
            '_lifetime.start' not in body.group(1) and '_lifetime.keep' not in body.group(1) and
            'prepareScene:' not in body.group(1),
            'Presentation changes must honor lifetime without recreating a scene or extending its deadline')
require('if (!_presentation.minimized()) {' in owned_trial and
        'if (minimized) return self.content.bounds.size.width > 0 && self.content.bounds.size.height > 0;' in owned_trial,
        'Minimized geometry must preserve a positive expanded viewport without fitting a zero-height bar')
require('[(NSDictionary *)manifest count] == 1 && !manifest[@"UISceneConfigurations"]' in capability_source and
        'declared-programmatic-application-scenes' in capability_source and
        'installed-basic-multiscene-v4' in capability_source,
        'Programmatic eligibility must require the exact absent-key shape under the new policy')
programmatic_facts = json.loads((ROOT / 'PROGRAMMATIC_SCENE_TARGETS_23A355.json').read_text())
require(programmatic_facts['runtimeCompatibilityConfirmed'] is False and
        programmatic_facts['firmware'] == target_facts['firmware'] and
        {app['bundleIdentifier'] for app in programmatic_facts['applications']} ==
            {'com.apple.mobilecal', 'com.apple.Preview'} and all(
            app['packageType'] == 'APPL' and 1 in app['deviceFamilies'] and
            app['declaresMultipleScenes'] is True and app['configurationDeclarationsPresent'] is False and
            app['sceneManifestKeys'] == ['UIApplicationSupportsMultipleScenes'] and
            app['otherSceneOrWindowKeys'] == [] and re.fullmatch(r'[0-9a-f]{64}', app['infoSHA256'])
            for app in programmatic_facts['applications']),
        'Programmatic facts must remain separate advisory declarations, never baseline permission')
require('configurationCount == 0 || configurationCount > 8' in capability_source and
        'BOOL namedMultiple = configurationCount > 1;' in capability_source and
        '[names containsObject:name]' in capability_source and
        'stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet' in capability_source and
        'declared-named-application-configurations' in capability_source,
        'Named configuration eligibility must remain bounded and reject blank or duplicate names')
named_facts = json.loads((ROOT / 'NAMED_CONFIGURATION_SCENE_TARGETS_23A355.json').read_text())
named_keys = {'UISceneConfigurationName', 'UISceneClassName', 'UISceneDelegateClassName', 'UISceneStoryboardFile'}
require(named_facts['runtimeCompatibilityConfirmed'] is False and
        named_facts['firmware'] == target_facts['firmware'] and
        {app['bundleIdentifier']: len(app['applicationRoleConfigurations']) for app in named_facts['applications']} ==
            {'com.apple.DocumentsApp': 2, 'com.apple.mobilemail': 4} and all(
            app['packageType'] == 'APPL' and 1 in app['deviceFamilies'] and app['declaresMultipleScenes'] is True and
            app['sceneManifestKeys'] == ['UIApplicationSupportsMultipleScenes', 'UISceneConfigurations'] and
            app['roleKeys'] == ['UIWindowSceneSessionRoleApplication'] and
            app['otherSceneOrWindowKeys'] == [] and re.fullmatch(r'[0-9a-f]{64}', app['infoSHA256']) and
            2 <= len(app['applicationRoleConfigurations']) <= 8 and
            len({c['UISceneConfigurationName'] for c in app['applicationRoleConfigurations']}) ==
                len(app['applicationRoleConfigurations']) and all(
                set(c) <= named_keys and all(isinstance(v, str) and 0 < len(v) <= 256 for v in c.values()) and
                c['UISceneConfigurationName'].strip() for c in app['applicationRoleConfigurations'])
            for app in named_facts['applications']),
        'Named facts must retain bounded application-only declarations and never become baseline permission')
require('childView.frame =' in owned_trial and
        owned_trial.index('childView.frame =') < owned_trial.index('[root addChildViewController:child]'),
        'Provide public native child geometry before attachment/appearance')
require('self.cleanupPolls >= 8' in owned_trial and 'NSEC_PER_SEC / 4' in owned_trial and
        '_lifetime.evaluate(conditions)' in owned_trial and
        '_lifetime.keep(conditions)' in owned_trial,
        'Guarded explicit Keep policy and bounded asynchronous cleanup required')
lifetime = (ROOT / 'PPOWindowLifetime.h').read_text()
require('TimedSeconds = 15.0' in lifetime and 'ActivationGraceSeconds = 2.0' in lifetime and
        'if (!kept_ && elapsed >= TimedSeconds)' in lifetime,
        'Timed default and bounded initial activation grace must remain')
lock_source = (ROOT / 'PPOScreenLockState.mm').read_text()
require(lock_source.count('objc_msgSend') == 1 and 'sharedInstanceIfExists' in lock_source and
        '"sharedInstance"' not in lock_source and 'NSNull.null' in lock_source and
        'NSThread.isMainThread' in lock_source and 'if (!firmwareMatches)' in lock_source,
        'Lock guard must be main-only, version-gated and nonconstructing')
for forbidden in ('valueForKey:', 'object_getIvar', 'method_getImplementation', 'performSelector', 'setUILocked:'):
    require(forbidden not in lock_source, 'Unexpected lock guard operation: ' + forbidden)
require('8676BE2A-9484-3492-888E-7DE10333250F' in (ROOT / 'PPOScenePreflight.mm').read_text() and
        'SBDeviceLockStateChangedNotification' in owned_trial and
        'UIApplication.sharedApplication.protectedDataAvailable' in owned_trial and
        'self.events removeObjectAtIndex:2' in owned_trial,
        'Exact lock image, data guard and bounded terminal-event retention required')
notification_close = owned_trial.split('- (void)closeAfterNotification:(NSString *)reason {', 1)[1].split('- (void)pan:', 1)[0]
require('self.closePending = YES' in notification_close and 'self.window.hidden = YES' in notification_close and
        'dispatch_async(dispatch_get_main_queue()' in notification_close and
        'self.session close' not in notification_close,
        'Notification closure must defer private teardown until the poster unwinds')
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
prefs_source = (ROOT / 'PPOUserPreferences.mm').read_text()
settings_source = (ROOT / 'preferences/PPOSettingsController.mm').read_text()
require('PPOUserPreferences.mm' in production_sources and 'preferences' in (ROOT / 'Makefile').read_text(),
        'Shared preferences and Settings bundle must build with production')
require('CFPreferencesSetMultiple' in prefs_source and 'CFPreferencesSetAppValue' not in prefs_source and
        'PPOUserPreferencesChangedNotification' in prefs_source,
        'Preferences must update only validated keys in their own domain')
require('@"keyboardAvoiding": @NO' in prefs_source and
        '[key isEqual:@"keyboardAvoiding"]' in prefs_source and
        '@"keyboardAvoiding"' in settings_source and '@"Evită tastatura"' in settings_source,
        'Keyboard avoidance must be an explicit default-off Boolean in the own settings domain')
require('PPOInteractionIntent _intent' in picker_source and '_intent.current(intent)' in picker_source and
        '_intent.consume(intent)' in picker_source and 'PPOHandleInteraction' in picker_source and
        '_handleInteraction.tap' in picker_source and '_handleInteraction.finishPan' in picker_source and
        '_handleInteraction.rowSelection' in picker_source,
        'Separate handle reveal from explicit app selection while preserving one-shot scene intent')
pan_body = re.search(r'- \(void\)panned:\(UIPanGestureRecognizer \*\)recognizer \{(.*?)\n\}', picker_source, re.S)
require(pan_body is not None and 'inspectSelectedForIntent' not in pan_body.group(1) and
        'openPreparedApplication' not in pan_body.group(1),
        'Handle dragging may reveal choices or move an existing drawer, never request a new app scene')
require('PPOEdgeOverlayWindow' in picker_source and 'PPOOwnedPassthroughWindow' in owned_trial and
        'PPOEdgeDrawerPanelTranslation' in owned_trial and 'self.panelBaseFrame' in owned_trial,
        'Public fullscreen overlays must pass through and retain untransformed panel geometry')
require('PSViewController : UIViewController' in settings_source and 'PPOSettingsController : PSViewController' in settings_source,
        'Settings must use the verified base class with its own public controls')
for pattern in ('objc_msgSend', 'valueForKey:', 'performSelector', 'makeKeyAndVisible', 'becomeFirstResponder'):
    require(pattern not in settings_source, 'Unexpected Settings runtime operation: ' + pattern)
print('Source policy OK (not a runtime test)')

for arg in sys.argv[1:]:
    deb = Path(arg)
    def field(name):
        return subprocess.check_output(['dpkg-deb', '-f', str(deb), name], text=True).strip()
    require(field('Package') == 'com.renatasy83.pulloverpro.diagnostic', 'Unexpected package')
    require(field('Architecture') == 'iphoneos-arm64', 'Unexpected architecture')
    require(field('Version') == '1.0.7~rc8', 'Unexpected version')
    require('ellekit' in field('Depends'), 'ElleKit dependency missing')
    require('preferenceloader' in field('Depends'), 'PreferenceLoader dependency missing')
    require('bash' in field('Depends'), 'Lifecycle script interpreter dependency missing')
    payload = subprocess.check_output(['dpkg-deb', '--fsys-tarfile', str(deb)])
    base = 'var/jb/Library/MobileSubstrate/DynamicLibraries/'
    required = {base + 'PullOverProDiagnostic.dylib', base + 'PullOverProDiagnostic.plist',
                base + 'PPOMessengerReturnAgent.dylib', base + 'PPOMessengerReturnAgent.plist',
                'var/jb/usr/bin/ppo-apps', 'var/jb/usr/bin/ppo-open', 'var/jb/usr/bin/ppo-bridge',
                'var/jb/Library/LaunchDaemons/com.renatasy83.ppo.bridge.plist',
                'var/jb/usr/share/doc/com.renatasy83.pulloverpro.diagnostic/copyright',
                'var/jb/Library/PreferenceBundles/PullOverProPortPreferences.bundle/PullOverProPortPreferences',
                'var/jb/Library/PreferenceBundles/PullOverProPortPreferences.bundle/Info.plist',
                'var/jb/Library/PreferenceLoader/Preferences/PullOverPro.plist'}
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
            elif name.endswith('PullOverProPortPreferences.bundle/Info.plist'):
                info = plistlib.loads(archive.extractfile(member).read())
                require(info['CFBundleExecutable'] == 'PullOverProPortPreferences' and info['NSPrincipalClass'] == 'PPOSettingsController', 'Settings executable/controller mismatch')
            elif name.endswith('PreferenceLoader/Preferences/PullOverPro.plist'):
                require(plistlib.loads(archive.extractfile(member).read()) == plistlib.loads((ROOT / 'layout/Library/PreferenceLoader/Preferences/PullOverPro.plist').read_bytes()), 'Settings loader entry mismatch')
            elif name.endswith('.plist'):
                raw = archive.extractfile(member).read()
                if raw.startswith(b'bplist') or raw.lstrip().startswith(b'<?xml'):
                    bundle = 'com.facebook.Messenger' if name.endswith('PPOMessengerReturnAgent.plist') else 'com.apple.springboard'
                    require(plistlib.loads(raw) == {'Filter': {'Bundles': [bundle]}},
                            'Packaged binary/XML filter mismatch')
                else:
                    expected = '{Filter={Bundles=("com.facebook.Messenger");};}' if name.endswith('PPOMessengerReturnAgent.plist') else expected_filter
                    require(re.sub(r'\s+', '', raw.decode()) == expected,
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

