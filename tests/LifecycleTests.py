"""Run packaged lifecycle scripts against isolated fake launchctl binaries."""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = ['/var/jb/bin/launchctl', '/var/jb/usr/bin/launchctl',
              '/bin/launchctl', '/usr/bin/launchctl']
checks = 0

def check(value):
    global checks
    checks += 1
    assert value

with tempfile.TemporaryDirectory(prefix='ppo-lifecycle-') as temp:
    directory = Path(temp)
    log = directory / 'calls'
    environment = dict(os.environ, PPO_TEST_LOG=str(log))

    def run(script, argument='configure', binaries=(), loaded=False,
            failure=0, restart_failure=0):
        log.write_text('')
        text = (ROOT / 'layout/DEBIAN' / script).read_text()
        for index, candidate in enumerate(CANDIDATES):
            # Only rewrite explicit candidate tokens in the disposable copy.
            text = text.replace(' ' + candidate + ' ', f' @CANDIDATE{index}@ ')
            text = text.replace(' ' + candidate + ';', f' @CANDIDATE{index}@;')
        for index in range(len(CANDIDATES)):
            binary = directory / f'launchctl-{index}'
            if binary.exists():
                binary.unlink()
            if index in binaries:
                binary.write_text('''#!/bin/bash
printf '%s\\n' "$*" >> "$PPO_TEST_LOG"
case "$1" in
 print) exit "$PPO_TEST_PRINT_EXIT" ;;
 bootstrap) exit "$PPO_TEST_BOOTSTRAP_EXIT" ;;
 kickstart) exit "$PPO_TEST_KICKSTART_EXIT" ;;
 bootout) exit 0 ;;
esac
exit 99
''')
                binary.chmod(0o700)
            text = text.replace(f'@CANDIDATE{index}@', str(binary))
        check(all(candidate not in text for candidate in CANDIDATES))
        fixture = directory / 'lifecycle.sh'
        fixture.write_text(text)
        env = dict(environment, PPO_TEST_PRINT_EXIT='0' if loaded else '3',
                   PPO_TEST_BOOTSTRAP_EXIT=str(failure),
                   PPO_TEST_KICKSTART_EXIT=str(restart_failure))
        result = subprocess.run(['bash', str(fixture), argument], env=env,
                                capture_output=True, text=True, timeout=5)
        return result, log.read_text().splitlines()

    expected = ['print system/com.renatasy83.ppo.bridge',
                'bootstrap system /var/jb/Library/LaunchDaemons/com.renatasy83.ppo.bridge.plist']
    restarted = ['print system/com.renatasy83.ppo.bridge',
                 'kickstart -k system/com.renatasy83.ppo.bridge']
    for candidate in range(4):
        result, calls = run('postinst', binaries=(candidate,))
        check(result.returncode == 0 and calls == expected)
        result, calls = run('postinst', binaries=(candidate,), loaded=True)
        check(result.returncode == 0 and calls == restarted)
    # Repeated configure must reload an existing helper, rather than merely
    # accepting the old KeepAlive process or bootstrapping a duplicate job.
    for _ in range(2):
        result, calls = run('postinst', binaries=(1,), loaded=True)
        check(result.returncode == 0 and calls == restarted)
    result, calls = run('postinst', binaries=(1,), loaded=True, restart_failure=43)
    check(result.returncode == 43 and calls == restarted)
    # Failure is retryable; neither a failed restart nor its retry touches a
    # different service or falls back to bootstrap while this job is loaded.
    result, calls = run('postinst', binaries=(1,), loaded=True)
    check(result.returncode == 0 and calls == restarted)
    result, calls = run('postinst')
    check(result.returncode == 127 and not calls and 'not found' in result.stderr)
    result, calls = run('postinst', binaries=(1,), failure=42)
    check(result.returncode == 42 and calls == expected)
    result, calls = run('postinst', binaries=(1,))
    check(result.returncode == 0 and calls == expected)
    for argument in ['', 'abort-upgrade', 'abort-install', 'triggered']:
        result, calls = run('postinst', argument=argument, binaries=(1,), loaded=True)
        check(result.returncode == 0 and not calls)
    for argument in ['remove', 'upgrade', 'deconfigure']:
        result, calls = run('prerm', argument, binaries=(1,))
        check(result.returncode == 0 and calls == ['bootout system/com.renatasy83.ppo.bridge'])
    result, calls = run('prerm', 'remove')
    check(result.returncode == 0 and not calls and 'unavailable' in result.stderr)

print(f'Lifecycle tests passed: {checks} checks; rootless/system lookup, own-service upgrade/retries, failure propagation and own-service removal.')
