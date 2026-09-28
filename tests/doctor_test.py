"""Exercise doctor without reading or changing the user's setup."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import TypedDict, override

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "scripts/doctor").read_text()
FUNCTIONS, SEPARATOR, _ = SCRIPT.partition('report "dotfiles checkout at ~/.dotfiles"')
if not SEPARATOR:
    message = "doctor entry point changed; update the function test loader"
    raise RuntimeError(message)


class CommandResponse(TypedDict, total=False):
    """Allow only supported fields in executable fixture responses."""

    stdout: str
    stderr: str
    code: int


class DoctorTests(unittest.TestCase):
    """Keep probe inputs separate from the host's real account and key material."""

    @override
    def setUp(self) -> None:
        bash = shutil.which("bash")
        if bash is None:
            self.fail("bash must be installed")
        self.bash = bash
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / "home"
        self.home.mkdir()
        tools = self.root / "tools"
        tools.mkdir()
        self.responses = self.root / "responses.json"
        self.log = self.root / "calls.jsonl"
        dispatcher = tools / "dispatch"
        dispatcher.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\nfrom pathlib import Path\n"
            "name = Path(sys.argv[0]).name\n"
            "with open(os.environ['TEST_CALLS'], 'a') as log:\n"
            "    log.write(json.dumps([name, *sys.argv[1:]]) + '\\n')\n"
            "responses = json.loads(Path(os.environ['TEST_RESPONSES']).read_text())\n"
            "response = responses.get(name, {})\n"
            "sys.stdout.write(response.get('stdout', ''))\n"
            "sys.stderr.write(response.get('stderr', ''))\n"
            "sys.exit(response.get('code', 0))\n"
        )
        dispatcher.chmod(0o755)
        for name in ("gpg", "dscl", "getent", "uname", "id", "readlink"):
            (tools / name).symlink_to(dispatcher)
        self.env = {
            key: value
            for key, value in os.environ.items()
            if key not in {"GNUPGHOME", "PASSWORD_STORE_DIR", "XDG_CONFIG_HOME"}
        }
        self.env.update(
            HOME=str(self.home),
            PATH=str(tools) + os.pathsep + os.environ["PATH"],
            TEST_CALLS=str(self.log),
            TEST_RESPONSES=str(self.responses),
        )
        self.commands: dict[str, CommandResponse] = {
            "uname": {"stdout": "Darwin\n"},
            "id": {"stdout": "test-user\n"},
            "dscl": {"stdout": "UserShell: /bin/zsh\n"},
            "getent": {"stdout": "test-user:x:1000:1000::/home/test-user:/bin/zsh\n"},
        }

    def _run(self, *args: str) -> subprocess.CompletedProcess[str]:
        self.responses.write_text(json.dumps(self.commands))
        return subprocess.run(
            [self.bash, *args],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )

    def run_shell(self, code: str) -> subprocess.CompletedProcess[str]:
        return self._run("-c", FUNCTIONS + "\n" + code)

    def probe(self, name: str, *, expected: bool) -> None:
        result = self.run_shell(f"if {name}; then exit 0; else exit 1; fi")
        self.assertEqual(result.returncode, 0 if expected else 1, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def file(self, path: str, contents: str = "") -> Path:
        target = self.home / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(contents)
        return target

    def calls(self) -> list[list[str]]:
        return (
            [json.loads(line) for line in self.log.read_text().splitlines()]
            if self.log.exists()
            else []
        )

    def test_checkout_requires_flake(self) -> None:
        self.probe("has_dotfiles_checkout", expected=False)
        self.file(".dotfiles/README.md")
        self.probe("has_dotfiles_checkout", expected=False)
        self.file(".dotfiles/flake.nix", "{}")
        self.probe("has_dotfiles_checkout", expected=True)

    def test_shell_comes_from_account_not_environment(self) -> None:
        self.env["SHELL"] = "/bin/bash"
        self.probe("has_zsh_login_shell", expected=True)
        self.commands["dscl"]["stdout"] = "UserShell: /bin/bash\n"
        self.env["SHELL"] = "/bin/zsh"
        self.probe("has_zsh_login_shell", expected=False)
        self.commands["uname"]["stdout"] = "Linux\n"
        self.probe("has_zsh_login_shell", expected=True)
        self.commands["getent"]["stdout"] = (
            "test-user:x:1000:1000::/home/test-user:/bin/bash\n"
        )
        self.probe("has_zsh_login_shell", expected=False)

    def test_ssh_requires_matching_key_pair(self) -> None:
        self.probe("has_ssh_key_pair", expected=False)
        self.file(".ssh/id_ed25519.pub", "public")
        self.probe("has_ssh_key_pair", expected=False)
        self.file(".ssh/id_other", "private fixture")
        self.probe("has_ssh_key_pair", expected=False)
        self.file(".ssh/id_ed25519", "private fixture")
        self.probe("has_ssh_key_pair", expected=True)

    def test_gpg_does_not_run_without_existing_keyring(self) -> None:
        self.probe("has_gpg_secret_key", expected=False)
        self.assertEqual(self.calls(), [])
        self.assertFalse((self.home / ".config/gnupg").exists())

    def test_gpg_flags_and_key_detection(self) -> None:
        directory = self.home / "custom-keyring"
        self.env["GNUPGHOME"] = str(directory)
        self.file("custom-keyring/pubring.kbx")
        self.commands["gpg"] = {"stdout": "pub:-:255:22:fixture\n"}
        self.probe("has_gpg_secret_key", expected=False)
        self.commands["gpg"]["stdout"] = "sec:-:255:22:fixture\n"
        self.probe("has_gpg_secret_key", expected=True)
        for call in self.calls():
            self.assertEqual(
                call,
                [
                    "gpg",
                    "--homedir",
                    str(directory),
                    "--batch",
                    "--no-autostart",
                    "--no-auto-check-trustdb",
                    "--with-colons",
                    "--list-secret-keys",
                ],
            )
        self.commands["gpg"] = {"code": 2}
        self.probe("has_gpg_secret_key", expected=False)

    def test_gpg_xdg_and_legacy_keyring(self) -> None:
        self.env["XDG_CONFIG_HOME"] = str(self.home / "xdg")
        self.file("xdg/gnupg/pubring.gpg")
        self.commands["gpg"] = {"stdout": "sec:-:255:22:fixture\n"}
        self.probe("has_gpg_secret_key", expected=True)
        self.assertEqual(self.calls()[0][2], str(self.home / "xdg/gnupg"))

    def test_pass_store_override(self) -> None:
        self.probe("has_pass_store", expected=False)
        self.file(".password-store/.gpg-id", "fixture")
        self.probe("has_pass_store", expected=True)
        self.env["PASSWORD_STORE_DIR"] = str(self.home / "alternate")
        self.probe("has_pass_store", expected=False)
        self.file("alternate/.gpg-id", "fixture")
        self.probe("has_pass_store", expected=True)

    def test_agenix_requires_readable_managed_target(self) -> None:
        self.commands["readlink"] = {"code": 1}
        self.probe("has_agenix_npmrc", expected=False)
        self.file(".npmrc", "non-secret fixture")
        self.commands["readlink"] = {"stdout": "/other/npmrc\n"}
        self.probe("has_agenix_npmrc", expected=False)
        self.commands["readlink"] = {"stdout": "/run/agenix/npmrc\n"}
        self.probe("has_agenix_npmrc", expected=True)
        (self.home / ".npmrc").unlink()
        self.probe("has_agenix_npmrc", expected=False)

    def test_report_counts_only_failures(self) -> None:
        result = self.run_shell(
            'report "present" true; report "absent" false; printf "%s\\n" "$failures"'
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "[ok] present\n[!!] absent\n1\n")
        self.assertEqual(result.stderr, "")

    def test_complete_home(self) -> None:
        for path in (
            ".dotfiles/flake.nix",
            ".ssh/id_ed25519",
            ".ssh/id_ed25519.pub",
            ".config/gnupg/pubring.kbx",
            ".password-store/.gpg-id",
            ".npmrc",
        ):
            self.file(path, "fixture")
        self.commands["gpg"] = {"stdout": "sec:-:255:22:fixture\n"}
        self.commands["readlink"] = {"stdout": "/run/agenix/npmrc\n"}
        result = self._run(str(ROOT / "scripts/doctor"))
        self.assertEqual(result.stderr, "")
        if Path("/run/current-system").exists():
            self.assertEqual(result.returncode, 0)
            self.assertTrue(result.stdout.endswith("All checks passed\n"))
        else:
            self.assertEqual(result.returncode, 1)
            self.assertEqual(
                [
                    line
                    for line in result.stdout.splitlines()
                    if line.startswith("[!!]")
                ],
                ["[!!] system generation active at /run/current-system"],
            )

    def test_full_script_exit_status_and_read_only_home(self) -> None:
        before = list(self.home.rglob("*"))
        result = self._run(str(ROOT / "scripts/doctor"))
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr, "")
        failures = sum(line.startswith("[!!]") for line in result.stdout.splitlines())
        self.assertGreater(failures, 0)
        self.assertTrue(result.stdout.endswith(f"{failures} check(s) failed\n"))
        self.assertEqual(list(self.home.rglob("*")), before)
        self.assertFalse(any(call[0] == "gpg" for call in self.calls()))


if __name__ == "__main__":
    unittest.main()
