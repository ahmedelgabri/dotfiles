"""Exercise real providers without sharing the user's configuration or cache."""

import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class LiveGetPrayerTests(unittest.TestCase):
    """Keep fallback coverage independent of provider response fixtures."""

    def test_real_providers_and_fallback(self) -> None:
        bash = shutil.which("bash")
        if bash is None:
            self.fail("bash must be installed")
        for key in ("MAWAQIT_USERNAME", "MAWAQIT_PASSWORD"):
            self.assertTrue(os.environ.get(key), f"{key} must be set")
        binary = os.environ.get("NEXT_PRAYER_BIN") or shutil.which("next-prayer")
        if binary is None:
            self.fail("Set NEXT_PRAYER_BIN to the built executable")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "next-prayer").symlink_to(Path(binary).resolve())
            env = {
                key: value
                for key, value in os.environ.items()
                if not key.startswith(("ALADHAN_", "MAWAQIT_")) and key != "DEBUG"
            }
            env.update(
                HOME=directory,
                XDG_CONFIG_HOME=directory,
                TMPDIR=directory,
                PATH=directory + os.pathsep + os.environ["PATH"],
            )
            for key in ("MAWAQIT_USERNAME", "MAWAQIT_PASSWORD"):
                env[key] = os.environ[key]

            def run(args: list[str]) -> subprocess.CompletedProcess[str]:
                result = subprocess.run(
                    args,
                    env=env,
                    text=True,
                    capture_output=True,
                    timeout=45,
                    check=False,
                )
                error = result.stderr
                for key in ("MAWAQIT_USERNAME", "MAWAQIT_PASSWORD"):
                    error = error.replace(os.environ[key], "[redacted]")
                self.assertEqual(result.returncode, 0, error)
                return result

            listing = run([
                binary,
                "mawaqit",
                "--latitude",
                "52.3676",
                "--longitude",
                "4.9041",
                "--list-mosques",
            ])
            self.assertEqual(listing.stderr, "")
            match = re.search(r"^  UUID:    (\S+)$", listing.stdout, re.MULTILINE)
            if match is None:
                self.fail("No mosque returned near Amsterdam")
            config = root / "prayer-times"
            config.mkdir()
            (config / "config.toml").write_text(
                f'[mawaqit]\nmosque="{match[1]}"\n'
                '[aladhan]\ncity="Amsterdam"\ncountry="NL"\nmethod=3\n'
            )
            location = root / ".location.json"
            location.write_text(
                json.dumps({
                    "location": {"latitude": 52.3676, "longitude": 4.9041},
                    "locality": "Amsterdam",
                    "countryCode": "NL",
                })
            )
            command = [
                bash,
                str(ROOT / "config/tmux/scripts/get-prayer"),
                "--json",
            ]
            result = run(command)
            self.assertEqual(result.stderr, "")
            schedule = json.loads(result.stdout)
            self.assertEqual(schedule["source"], "mawaqit")
            self.assertEqual(schedule["mosque"]["uuid"], match[1])

            # No location takes the public API path rather than the mosque cache.
            location.unlink()
            result = run(command)
            self.assertEqual(result.stderr, "")
            self.assertEqual(json.loads(result.stdout)["source"], "aladhan")

            # A credential validation failure must also fall back through the real CLI.
            location.write_text(
                json.dumps({"location": {"latitude": 52.3677, "longitude": 4.9042}})
            )
            del env["MAWAQIT_USERNAME"]
            del env["MAWAQIT_PASSWORD"]
            result = run(command)
            self.assertEqual(
                result.stderr, "error: mawaqit username and password are required\n"
            )
            self.assertEqual(json.loads(result.stdout)["source"], "aladhan")


if __name__ == "__main__":
    unittest.main()
