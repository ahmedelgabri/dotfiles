"""Use the real desktop runtime without replacing its active prayer module."""

import json
import os
import shlex
import shutil
import subprocess
import tempfile
import time
import unittest
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class LiveHammerspoonPrayerTests(unittest.TestCase):
    """Verify actual task and calendar APIs without sending notifications."""

    def test_real_fetch_and_calendar_without_touching_active_module(self) -> None:
        hs = shutil.which("hs")
        if hs is None:
            self.fail("The Hammerspoon CLI and app must be available")
        binary = os.environ.get("NEXT_PRAYER_BIN") or shutil.which("next-prayer")
        if binary is None:
            self.fail("next-prayer must be available")
        bash = shutil.which("bash")
        if bash is None:
            self.fail("bash must be installed")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "next-prayer").symlink_to(Path(binary).resolve())
            config = root / "prayer-times"
            config.mkdir()
            (config / "config.toml").write_text(
                '[aladhan]\ncity="Amsterdam"\ncountry="NL"\nmethod=3\n'
            )
            launcher = root / "get-prayer"
            wrapper = ROOT / "config/tmux/scripts/get-prayer"
            path = directory + os.pathsep + os.environ["PATH"]
            launcher.write_text(
                "#!/bin/bash\n"
                f"export HOME={shlex.quote(directory)}\n"
                f"export XDG_CONFIG_HOME={shlex.quote(directory)}\n"
                f"export TMPDIR={shlex.quote(directory)}\n"
                f"export PATH={shlex.quote(path)}\n"
                f'exec {shlex.quote(bash)} {shlex.quote(str(wrapper))} "$@"\n'
            )
            launcher.chmod(0o755)
            key = "dotfiles_prayer_test_" + uuid.uuid4().hex

            def execute(code: str) -> str:
                result = subprocess.run(
                    [hs, "-c", code],
                    text=True,
                    capture_output=True,
                    timeout=30,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stderr, "")
                lines = result.stdout.strip().splitlines()
                for line in lines[:-1]:
                    self.assertTrue(
                        any(
                            message in line
                            for message in (
                                "Fetching prayer schedule with get-prayer",
                                "Prayer schedule fetch completed",
                            )
                        ),
                        f"Unexpected Hammerspoon log: {line}",
                    )
                return lines[-1]

            code = f"""
local env = setmetatable({{}}, {{__index = _G}})
local modules = {{}}
local modulePath = {json.dumps(str(ROOT / "config/.hammerspoon"))}
env.require = function(name)
    assert(name == 'utils' or name == 'log')
    if not modules[name] then
        local path = modulePath .. '/' .. name .. '.lua'
        modules[name] = assert(loadfile(path, 't', env))()
    end
    return modules[name]
end
local prayer = assert(loadfile(modulePath .. '/prayer.lua', 't', env))()
prayer.settings.notificationsEnabled = false
prayer.settings.fetchCommand = {json.dumps(str(launcher))}
prayer.settings.fetchShell = '/bin/bash'
prayer.settings.locationPath = {json.dumps(str(root / ".location.json"))}
_G[{json.dumps(key)}] = {{prayer = prayer, original = package.loaded.prayer}}
prayer.update()
return 'started'
"""
            try:
                self.assertIn("started", execute(code))
                deadline = time.monotonic() + 60
                while time.monotonic() < deadline:
                    output = execute(f"""
local value = assert(_G[{json.dumps(key)}])
assert(package.loaded.prayer == value.original, 'active prayer module changed')
local p = value.prayer
if not p.fetchState.running then p.update() end
return hs.json.encode(p.getStatus())
""")
                    status = json.loads(output)
                    if not status["fetch"]["running"]:
                        break
                    time.sleep(0.2)
                else:
                    self.fail("Hammerspoon fetch did not complete within 60 seconds")
                self.assertIsNone(status.get("error"))
                self.assertIsNone(status["fetch"].get("error"))
                self.assertEqual(status["source"], "aladhan")
                self.assertEqual(status["rowCount"], 5)
                self.assertIn(
                    status["nextPrayer"]["key"],
                    ("fajr", "dhuhr", "asr", "maghrib", "isha"),
                )
                self.assertGreater(status["hijriDate"]["year"], 1400)
                self.assertFalse(status["notificationsEnabled"])
                self.assertFalse(status["notificationScheduled"])
            finally:
                execute(
                    f"local key = {json.dumps(key)}; local v = _G[key]; "
                    'if v then v.prayer.stop(); _G[key] = nil end; return "cleaned"'
                )


if __name__ == "__main__":
    unittest.main()
