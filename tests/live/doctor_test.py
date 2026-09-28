import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


def snapshot(root):
    result = {}
    for path in root.rglob("*"):
        name = str(path.relative_to(root))
        if path.is_symlink():
            result[name] = ("symlink", os.readlink(path))
        elif path.is_file():
            result[name] = ("file", hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            result[name] = ("directory", path.stat().st_mode)
    return result


class LiveDoctorTests(unittest.TestCase):
    def test_real_tools_do_not_modify_home_or_start_gpg_agent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".dotfiles").symlink_to(ROOT, target_is_directory=True)
            ssh = root / ".ssh"
            ssh.mkdir(mode=0o700)
            generated = subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", "doctor-e2e",
                                        "-f", str(ssh / "id_ed25519")], text=True, capture_output=True, timeout=15)
            self.assertEqual(generated.returncode, 0, generated.stderr)
            self.assertEqual(generated.stdout + generated.stderr, "")
            env = os.environ | {"HOME": directory, "XDG_CONFIG_HOME": str(root / ".config"),
                                "GNUPGHOME": str(root / "gnupg"), "PASSWORD_STORE_DIR": str(root / "pass")}
            socket = subprocess.run(["gpgconf", "--list-dirs", "agent-socket"], env=env,
                                    text=True, capture_output=True, timeout=10)
            self.assertEqual(socket.returncode, 0, socket.stderr)
            self.assertEqual(socket.stderr, "")
            agent_socket = Path(socket.stdout.strip())
            self.assertFalse(agent_socket.exists())
            before = snapshot(root)
            result = subprocess.run([shutil.which("bash"), str(ROOT / "scripts/doctor")], env=env,
                                    text=True, capture_output=True, timeout=15)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stderr, "")
            self.assertIn("[ok] dotfiles checkout at ~/.dotfiles\n", result.stdout)
            self.assertIn("[ok] SSH key pair in ~/.ssh\n", result.stdout)
            self.assertIn("[!!] GPG secret key (git commits are signed)\n", result.stdout)
            self.assertIn("[!!] pass store initialised\n", result.stdout)
            failures = sum(line.startswith("[!!]") for line in result.stdout.splitlines())
            self.assertTrue(result.stdout.endswith(f"{failures} check(s) failed\n"))
            self.assertEqual(snapshot(root), before)
            self.assertFalse(agent_socket.exists())
            self.assertFalse((root / "gnupg").exists())


if __name__ == "__main__":
    unittest.main()
