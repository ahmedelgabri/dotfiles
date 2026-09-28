"""Check wrapper arguments separately from provider API availability."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import override

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "config/tmux/scripts/get-prayer"


class GetPrayerTests(unittest.TestCase):
    """Use controlled provider responses to exercise every fallback branch."""

    @override
    def setUp(self) -> None:
        bash = shutil.which("bash")
        if bash is None:
            self.fail("bash must be installed")
        self.bash = bash
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.calls_file = self.root / "calls.jsonl"
        self.location_file = self.root / ".location.json"
        binary = self.root / "next-prayer"
        binary.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['TEST_CALLS'], 'a') as calls:\n"
            "    calls.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "source = sys.argv[1].upper()\n"
            "status = int(os.environ.get('TEST_' + source + '_STATUS', '0'))\n"
            "if status:\n"
            "    print(sys.argv[1] + ' unavailable', file=sys.stderr)\n"
            "    sys.exit(status)\n"
            "print(os.environ.get('TEST_' + source + '_OUTPUT', 'Fajr: 04:00'))\n"
        )
        binary.chmod(0o755)
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(("MAWAQIT_", "ALADHAN_", "TEST_")) and key != "DEBUG"
        }
        self.env.update(
            PATH=str(self.root) + os.pathsep + os.environ["PATH"],
            HOME=str(self.root),
            XDG_CONFIG_HOME=str(self.root),
            TMPDIR=str(self.root),
            TEST_CALLS=str(self.calls_file),
        )

    def location(self, **changes: object) -> None:
        data: dict[str, object] = {
            "location": {"latitude": 52.3676, "longitude": 4.9041},
            "locality": "Amsterdam",
            "countryCode": "NL",
        }
        data.update(changes)
        self.location_file.write_text(json.dumps(data))

    def run_wrapper(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [self.bash, str(WRAPPER), *args],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )

    def calls(self) -> list[list[str]]:
        return [json.loads(line) for line in self.calls_file.read_text().splitlines()]

    def test_missing_location_uses_aladhan(self) -> None:
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "Fajr: 04:00")
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls(), [["aladhan"]])

    def test_malformed_location_uses_aladhan(self) -> None:
        self.location_file.write_text("{broken")
        result = self.run_wrapper("--json")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls(), [["aladhan", "-json"]])

    def test_complete_location_uses_mawaqit(self) -> None:
        self.location(locality="Den Haag")
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "\U000f0a77 Fajr: 04:00")
        self.assertEqual(result.stderr, "")
        self.assertEqual(
            self.calls(),
            [
                [
                    "mawaqit",
                    "-latitude",
                    "52.3676",
                    "-longitude",
                    "4.9041",
                    "-city",
                    "Den Haag",
                    "-country",
                    "NL",
                ]
            ],
        )

    def test_json_is_not_decorated(self) -> None:
        self.location()
        self.env["TEST_MAWAQIT_OUTPUT"] = '{"source":"mawaqit","timings":{}}'
        result = self.run_wrapper("--json")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, self.env["TEST_MAWAQIT_OUTPUT"])
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls()[0][1], "-json")

    def test_mawaqit_failure_falls_back(self) -> None:
        self.location()
        self.env["TEST_MAWAQIT_STATUS"] = "1"
        self.env["TEST_ALADHAN_OUTPUT"] = '{"source":"aladhan","timings":{}}'
        result = self.run_wrapper("--json")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, self.env["TEST_ALADHAN_OUTPUT"])
        self.assertEqual(result.stderr, "mawaqit unavailable\n")
        self.assertEqual([call[0] for call in self.calls()], ["mawaqit", "aladhan"])
        self.assertEqual(self.calls()[1], ["aladhan", "-json"])

    def test_missing_latitude_does_not_shift_fields(self) -> None:
        self.location(location={"longitude": 4.9041})
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls(), [["aladhan"]])

    def test_missing_longitude_does_not_shift_fields(self) -> None:
        self.location(location={"latitude": 52.3676})
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls(), [["aladhan"]])

    def test_missing_city_preserves_country(self) -> None:
        self.location(locality=None)
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls()[0][-4:], ["-city", "", "-country", "NL"])

    def test_both_provider_failures_return_failure(self) -> None:
        self.location()
        self.env.update(TEST_MAWAQIT_STATUS="1", TEST_ALADHAN_STATUS="2")
        result = self.run_wrapper("--json")
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "mawaqit unavailable\naladhan unavailable\n")
        self.assertEqual(result.returncode, 2)


class WrapperIntegrationTests(unittest.TestCase):
    """Verify exit-status propagation against the installed CLI, without network."""

    def test_real_cli_failure_is_propagated(self) -> None:
        bash = shutil.which("bash")
        if bash is None:
            self.fail("bash must be installed")
        binary = os.environ.get("NEXT_PRAYER_BIN") or shutil.which("next-prayer")
        if binary is None:
            self.fail("Set NEXT_PRAYER_BIN to the built next-prayer executable")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "next-prayer").symlink_to(Path(binary).resolve())
            env = {
                key: value
                for key, value in os.environ.items()
                if not key.startswith(("MAWAQIT_", "ALADHAN_")) and key != "DEBUG"
            }
            env.update(
                HOME=directory,
                XDG_CONFIG_HOME=directory,
                TMPDIR=directory,
                PATH=directory + os.pathsep + os.environ["PATH"],
            )
            result = subprocess.run(
                [bash, str(WRAPPER), "--json"],
                env=env,
                text=True,
                capture_output=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertEqual(result.stderr, "error: aladhan city is required\n")


if __name__ == "__main__":
    unittest.main()
