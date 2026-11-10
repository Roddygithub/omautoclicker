#!/usr/bin/env python3
"""Opt-in real desktop test. Requires the installed plugin and ydotoold."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from datetime import datetime, timezone


def run(*args, check=True, timeout=8):
    return subprocess.run(args, text=True, capture_output=True, timeout=timeout, check=check).stdout.strip()


def service(method, *args):
    return run('omarchy-shell', 'omautoclicker', method, *map(str, args))


def state():
    return json.loads(service('status'))


def wait_for(predicate, seconds=8):
    until = time.monotonic() + seconds
    while time.monotonic() < until:
        result = predicate()
        if result:
            return result
        time.sleep(.08)
    raise AssertionError('Timed out waiting for test condition')


if __name__ == '__main__':
    instance = json.loads(run('hyprctl', '-j', 'instances'))[0]
    os.environ.update(HYPRLAND_INSTANCE_SIGNATURE=instance['instance'],
                      WAYLAND_DISPLAY=instance['wl_socket'], QT_QPA_PLATFORM='wayland')
    original = state()
    assert original['phase'] == 'idle', 'Stop the current sequence before testing'
    cursor = json.loads(run('hyprctl', '-j', 'cursorpos'))
    active = json.loads(run('hyprctl', '-j', 'activewindow')).get('address')
    report = {'at': datetime.now(timezone.utc).isoformat(), 'tests': []}
    with tempfile.TemporaryDirectory(prefix='omautoclicker-live-') as folder:
        shell = str(Path(folder) / 'shell.qml')
        shutil.copy(Path(__file__).with_name('LiveTarget.qml'), shell)
        log = open(Path(folder) / 'output.log', 'w+')
        process = subprocess.Popen(['qs', '-p', shell, '--no-color'], stdout=log, stderr=log)

        def target(method):
            return run('qs', 'ipc', '-p', shell, 'call', 'liveTarget', method)

        def received():
            return json.loads(target('status'))

        def reset():
            assert received()['inside'], 'Pointer left the safe test area'
            target('reset')

        def passed(name, **details):
            report['tests'].append({'name': name, 'passed': True, **details})
            print(json.dumps(report['tests'][-1]), flush=True)

        try:
            client = wait_for(lambda: next((x for x in json.loads(run('hyprctl', '-j', 'clients'))
                                           if x['pid'] == process.pid), None))
            run('hyprctl', 'dispatch', 'hl.dsp.focus({window=' + json.dumps('address:' + client['address']) + '})')
            x, y = client['at']
            w, h = client['size']
            run('hyprctl', 'dispatch', f'hl.dsp.cursor.move({{x={x+w//2},y={y+h//2}}})')
            wait_for(lambda: received()['inside'])
            for button in ('left', 'right', 'middle'):
                reset()
                assert service('configure', 100, button, 5, 1) == 'true'
                assert service('start') == 'true'
                wait_for(lambda: state()['phase'] == 'idle' and state()['count'] == 5)
                time.sleep(.3)
                counts = received()
                assert counts['inside']
                assert counts['presses'][button] == counts['releases'][button] == 5, counts
                assert sum(counts['presses'].values()) == 5, counts
                passed(button, presses=counts['presses'], releases=counts['releases'])

            reset()
            service('configure', 100, 'left', 20, 3)
            service('start')
            time.sleep(.3)
            service('stop')
            time.sleep(3.2)
            assert state()['count'] == 0 and sum(received()['presses'].values()) == 0
            passed('cancel_countdown', clicks=0)

            reset()
            service('configure', 100, 'left', 20, 1)
            run('ydotool', 'key', '--key-delay', '0', '66:1', '66:0')  # F8
            wait_for(lambda: state()['count'] >= 3)
            run('ydotool', 'key', '--key-delay', '0', '67:1', '67:0')  # F9
            wait_for(lambda: state()['phase'] == 'idle')
            time.sleep(.3)
            stopped = received()
            time.sleep(.5)
            assert received()['presses'] == stopped['presses']
            assert stopped['presses'] == stopped['releases']
            assert 3 <= stopped['presses']['left'] < 20
            passed('F8_start_F9_stop', clicks=stopped['presses']['left'])

            reset()
            service('start')
            wait_for(lambda: state()['count'] >= 2)
            run('omarchy', 'plugin', 'disable', 'roddy.omautoclicker')
            time.sleep(.4)
            stopped = received()
            time.sleep(.5)
            assert received()['presses'] == stopped['presses']
            assert stopped['presses'] == stopped['releases']
            run('omarchy', 'plugin', 'enable', 'roddy.omautoclicker', '--section', 'right')
            wait_for(lambda: service('status') if run('omarchy-shell', 'omautoclicker', 'status', check=False).startswith('{') else False)
            assert state()['phase'] == 'idle'
            assert state()['intervalMs'] == 100 and state()['limit'] == 20
            time.sleep(.4)
            assert received()['presses'] == stopped['presses']
            passed('disable_reenable_no_resume', clicks=stopped['presses']['left'], settings_preserved=True)
            reset()
            service('start')
            wait_for(lambda: state()['count'] >= 2)
            restart = subprocess.run(['omarchy', 'restart', 'shell'], capture_output=True, text=True, timeout=50)
            if restart.returncode:
                report['restart_command_warning'] = (restart.stdout + restart.stderr).strip()
                print('Restart command warning: ' + report['restart_command_warning'], flush=True)
            wait_for(lambda: run('omarchy-shell', 'omautoclicker', 'status', check=False).startswith('{'), seconds=12)
            assert state()['phase'] == 'idle' and state()['count'] == 0
            assert state()['intervalMs'] == 100 and state()['limit'] == 20
            stopped = received()
            time.sleep(.6)
            assert received()['presses'] == stopped['presses']
            assert stopped['presses'] == stopped['releases']
            passed('shell_restart_no_resume', clicks=stopped['presses']['left'], settings_preserved=True)
            report['passed'] = True
        finally:
            run('omarchy', 'plugin', 'enable', 'roddy.omautoclicker', '--section', 'right', check=False)
            wait_for(lambda: run('omarchy-shell', 'omautoclicker', 'status', check=False).startswith('{'), seconds=15)
            service('stop')
            time.sleep(.2)
            service('configure', original['intervalMs'], original['button'], original['limit'], original['delaySeconds'])
            process.terminate()
            process.wait(timeout=5)
            run('hyprctl', 'dispatch', f'hl.dsp.cursor.move({{x={cursor["x"]},y={cursor["y"]}}})', check=False)
            if active:
                run('hyprctl', 'dispatch', 'hl.dsp.focus({window=' + json.dumps('address:' + active) + '})', check=False)
            report['final_state'] = state()
            Path(__file__).with_name('live-results.json').write_text(json.dumps(report, indent=2) + '\n')
            log.seek(0)
            output = log.read()
            if 'WARN scene:' in output or 'ERROR' in output:
                print(output)
