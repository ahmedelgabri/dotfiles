"""Verify doctor is read-only with real tools and isolated key material."""

import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def snapshot(root: Path) -> dict[str, tuple[str, str | int]]:
    """Fingerprint content and links without traversing the checkout symlink.

    Returns:
        Relative paths mapped to content hashes, link targets, or directory modes.

    """
    result: dict[str, tuple[str, str | int]] = {}
    for path in root.rglob("*"):
        name = str(path.relative_to(root))
        if path.is_symlink():
            result[name] = ("symlink", str(path.readlink()))
        elif path.is_file():
            result[name] = ("file", hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            result[name] = ("directory", path.stat().st_mode)
    return result


class LiveDoctorTests(unittest.TestCase):
    """Detect unintended setup changes without touching the user's home."""

    def test_real_tools_do_not_modify_home_or_start_gpg_agent(self) -> None:
        tools: dict[str, str] = {}
        for name in ("bash", "ssh-keygen", "gpgconf"):
            binary = shutil.which(name)
            if binary is None:
                self.fail(f"{name} must be installed")
            tools[name] = binary
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".dotfiles").symlink_to(ROOT, target_is_directory=True)
            ssh = root / ".ssh"
            ssh.mkdir(mode=0o700)
            generated = subprocess.run(
                [
                    tools["ssh-keygen"],
                    "-q",
                    "-t",
                    "ed25519",
                    "-N",
                    "",
                    "-C",
                    "doctor-e2e",
                    "-f",
                    str(ssh / "id_ed25519"),
                ],
                text=True,
                capture_output=True,
                timeout=15,
                check=False,
            )
            self.assertEqual(generated.returncode, 0, generated.stderr)
            self.assertEqual(generated.stdout + generated.stderr, "")
            env = os.environ | {
                "HOME": directory,
                "XDG_CONFIG_HOME": str(root / ".config"),
                "GNUPGHOME": str(root / "gnupg"),
                "PASSWORD_STORE_DIR": str(root / "pass"),
            }
            socket = subprocess.run(
                [tools["gpgconf"], "--list-dirs", "agent-socket"],
                env=env,
                text=True,
                capture_output=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(socket.returncode, 0, socket.stderr)
            self.assertEqual(socket.stderr, "")
            agent_socket = Path(socket.stdout.strip())
            self.assertFalse(agent_socket.exists())
            before = snapshot(root)
            result = subprocess.run(
                [tools["bash"], str(ROOT / "scripts/doctor")],
                env=env,
                text=True,
                capture_output=True,
                timeout=15,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stderr, "")
            self.assertIn("[ok] dotfiles checkout at ~/.dotfiles\n", result.stdout)
            self.assertIn("[ok] SSH key pair in ~/.ssh\n", result.stdout)
            self.assertIn(
                "[!!] GPG secret key (git commits are signed)\n", result.stdout
            )
            self.assertIn("[!!] pass store initialised\n", result.stdout)
            failures = sum(
                line.startswith("[!!]") for line in result.stdout.splitlines()
            )
            self.assertTrue(result.stdout.endswith(f"{failures} check(s) failed\n"))
            self.assertEqual(snapshot(root), before)
            self.assertFalse(agent_socket.exists())
            self.assertFalse((root / "gnupg").exists())


if __name__ == "__main__":
    unittest.main()
