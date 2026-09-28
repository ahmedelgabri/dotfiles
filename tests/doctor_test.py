import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "scripts/doctor").read_text()
FUNCTIONS, SEPARATOR, _ = SCRIPT.partition('report "dotfiles checkout at ~/.dotfiles"')
assert SEPARATOR, "doctor entry point changed; update the function test loader"


class DoctorTests(unittest.TestCase):
    def setUp(self):
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
            "response = json.loads(Path(os.environ['TEST_RESPONSES']).read_text()).get(name, {})\n"
            "sys.stdout.write(response.get('stdout', ''))\n"
            "sys.stderr.write(response.get('stderr', ''))\n"
            "sys.exit(response.get('code', 0))\n"
        )
        dispatcher.chmod(0o755)
        for name in ("gpg", "dscl", "getent", "uname", "id", "readlink"):
            (tools / name).symlink_to(dispatcher)
        self.env = {key: value for key, value in os.environ.items()
                    if key not in ("GNUPGHOME", "PASSWORD_STORE_DIR", "XDG_CONFIG_HOME")}
        self.env.update(HOME=str(self.home), PATH=str(tools) + os.pathsep + os.environ["PATH"],
                        TEST_CALLS=str(self.log), TEST_RESPONSES=str(self.responses))
        self.commands = {"uname": {"stdout": "Darwin\n"}, "id": {"stdout": "test-user\n"},
                         "dscl": {"stdout": "UserShell: /bin/zsh\n"},
                         "getent": {"stdout": "test-user:x:1000:1000::/home/test-user:/bin/zsh\n"}}

    def run_shell(self, code):
        self.responses.write_text(json.dumps(self.commands))
        return subprocess.run([shutil.which("bash"), "-c", FUNCTIONS + "\n" + code], env=self.env,
                              text=True, capture_output=True, timeout=10)

    def probe(self, name, expected):
        result = self.run_shell(f"if {name}; then exit 0; else exit 1; fi")
        self.assertEqual(result.returncode, 0 if expected else 1, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def file(self, path, contents=""):
        target = self.home / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(contents)
        return target

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_checkout_requires_flake(self):
        self.probe("has_dotfiles_checkout", False)
        self.file(".dotfiles/README.md")
        self.probe("has_dotfiles_checkout", False)
        self.file(".dotfiles/flake.nix", "{}")
        self.probe("has_dotfiles_checkout", True)

    def test_shell_comes_from_account_not_environment(self):
        self.env["SHELL"] = "/bin/bash"
        self.probe("has_zsh_login_shell", True)
        self.commands["dscl"]["stdout"] = "UserShell: /bin/bash\n"
        self.env["SHELL"] = "/bin/zsh"
        self.probe("has_zsh_login_shell", False)
        self.commands["uname"]["stdout"] = "Linux\n"
        self.probe("has_zsh_login_shell", True)
        self.commands["getent"]["stdout"] = "test-user:x:1000:1000::/home/test-user:/bin/bash\n"
        self.probe("has_zsh_login_shell", False)

    def test_ssh_requires_matching_key_pair(self):
        self.probe("has_ssh_key_pair", False)
        self.file(".ssh/id_ed25519.pub", "public")
        self.probe("has_ssh_key_pair", False)
        self.file(".ssh/id_other", "private fixture")
        self.probe("has_ssh_key_pair", False)
        self.file(".ssh/id_ed25519", "private fixture")
        self.probe("has_ssh_key_pair", True)

    def test_gpg_does_not_run_without_existing_keyring(self):
        self.probe("has_gpg_secret_key", False)
        self.assertEqual(self.calls(), [])
        self.assertFalse((self.home / ".config/gnupg").exists())

    def test_gpg_flags_and_key_detection(self):
        directory = self.home / "custom-keyring"
        self.env["GNUPGHOME"] = str(directory)
        self.file("custom-keyring/pubring.kbx")
        self.commands["gpg"] = {"stdout": "pub:-:255:22:fixture\n"}
        self.probe("has_gpg_secret_key", False)
        self.commands["gpg"]["stdout"] = "sec:-:255:22:fixture\n"
        self.probe("has_gpg_secret_key", True)
        for call in self.calls():
            self.assertEqual(call, ["gpg", "--homedir", str(directory), "--batch", "--no-autostart",
                                    "--no-auto-check-trustdb", "--with-colons", "--list-secret-keys"])
        self.commands["gpg"] = {"code": 2}
        self.probe("has_gpg_secret_key", False)

    def test_gpg_xdg_and_legacy_keyring(self):
        self.env["XDG_CONFIG_HOME"] = str(self.home / "xdg")
        self.file("xdg/gnupg/pubring.gpg")
        self.commands["gpg"] = {"stdout": "sec:-:255:22:fixture\n"}
        self.probe("has_gpg_secret_key", True)
        self.assertEqual(self.calls()[0][2], str(self.home / "xdg/gnupg"))

    def test_pass_store_override(self):
        self.probe("has_pass_store", False)
        self.file(".password-store/.gpg-id", "fixture")
        self.probe("has_pass_store", True)
        self.env["PASSWORD_STORE_DIR"] = str(self.home / "alternate")
        self.probe("has_pass_store", False)
        self.file("alternate/.gpg-id", "fixture")
        self.probe("has_pass_store", True)

    def test_agenix_requires_readable_managed_target(self):
        self.commands["readlink"] = {"code": 1}
        self.probe("has_agenix_npmrc", False)
        self.file(".npmrc", "non-secret fixture")
        self.commands["readlink"] = {"stdout": "/other/npmrc\n"}
        self.probe("has_agenix_npmrc", False)
        self.commands["readlink"] = {"stdout": "/run/agenix/npmrc\n"}
        self.probe("has_agenix_npmrc", True)
        (self.home / ".npmrc").unlink()
        self.probe("has_agenix_npmrc", False)

    def test_report_counts_only_failures(self):
        result = self.run_shell('report "present" true; report "absent" false; printf "%s\\n" "$failures"')
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "[ok] present\n[!!] absent\n1\n")
        self.assertEqual(result.stderr, "")

    def test_complete_home(self):
        for path in (".dotfiles/flake.nix", ".ssh/id_ed25519", ".ssh/id_ed25519.pub",
                     ".config/gnupg/pubring.kbx", ".password-store/.gpg-id", ".npmrc"):
            self.file(path, "fixture")
        self.commands["gpg"] = {"stdout": "sec:-:255:22:fixture\n"}
        self.commands["readlink"] = {"stdout": "/run/agenix/npmrc\n"}
        self.responses.write_text(json.dumps(self.commands))
        result = subprocess.run([shutil.which("bash"), str(ROOT / "scripts/doctor")], env=self.env,
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(result.stderr, "")
        if Path("/run/current-system").exists():
            self.assertEqual(result.returncode, 0)
            self.assertTrue(result.stdout.endswith("All checks passed\n"))
        else:
            self.assertEqual(result.returncode, 1)
            self.assertEqual([line for line in result.stdout.splitlines() if line.startswith("[!!]")],
                             ["[!!] system generation active at /run/current-system"])

    def test_full_script_exit_status_and_read_only_home(self):
        self.responses.write_text(json.dumps(self.commands))
        before = list(self.home.rglob("*"))
        result = subprocess.run([shutil.which("bash"), str(ROOT / "scripts/doctor")], env=self.env,
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr, "")
        failures = sum(line.startswith("[!!]") for line in result.stdout.splitlines())
        self.assertGreater(failures, 0)
        self.assertTrue(result.stdout.endswith(f"{failures} check(s) failed\n"))
        self.assertEqual(list(self.home.rglob("*")), before)
        self.assertFalse(any(call[0] == "gpg" for call in self.calls()))


if __name__ == "__main__":
    unittest.main()
