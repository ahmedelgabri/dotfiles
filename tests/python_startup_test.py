"""Cover startup helpers and the real console without touching user history."""

import ast
import builtins
import contextlib
import io
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import TYPE_CHECKING, cast, override
from unittest.mock import patch

if TYPE_CHECKING:
    from code import InteractiveConsole
    from collections.abc import Callable, Mapping

STARTUP = Path(__file__).resolve().parents[1] / "config/python/.pythonrc.py"


class StartupUnitTests(unittest.TestCase):
    """Load definitions without installing hooks or starting an interactive shell."""

    @override
    def setUp(self) -> None:
        tree = ast.parse(STARTUP.read_text(encoding="utf-8"))
        tree.body = [
            node
            for node in tree.body
            if isinstance(
                node, (ast.Import, ast.ImportFrom, ast.ClassDef, ast.FunctionDef)
            )
        ]
        namespace: dict[str, object] = {"EDITOR": "editor --wait", "EDIT_CMD": r"\e"}
        # Only definitions from the checked-in startup script are executed.
        exec(compile(tree, str(STARTUP), "exec"), namespace)  # ruff: ignore[exec-builtin]
        self.colors = cast("Callable[[], Mapping[str, str]]", namespace["TermColors"])
        self.display = cast("Callable[[object], None]", namespace["my_displayhook"])
        self.console = cast(
            "type[InteractiveConsole]", namespace["EditableBufferInteractiveConsole"]
        )

    def test_supported_and_unknown_terminal_colors(self) -> None:
        with patch.dict(os.environ, TERM="xterm-256color"):
            self.assertEqual(self.colors()["Red"], "\001\033[0;31m\002")
        with patch.dict(os.environ, TERM="dumb"):
            self.assertFalse(any(self.colors().values()))

    def test_displayhook_updates_builtin_result_and_ignores_none(self) -> None:
        output = io.StringIO()
        with (
            patch.object(builtins, "_", None, create=True),
            contextlib.redirect_stdout(output),
        ):
            self.display([1, 2])
            self.assertEqual(vars(builtins)["_"], [1, 2])
            self.display(None)
            self.assertEqual(vars(builtins)["_"], [1, 2])
        self.assertEqual(output.getvalue(), "[1, 2]\n")

    def test_console_keeps_source_and_compiler_state(self) -> None:
        values: list[int] = []
        console = self.console(locals={"values": values})
        self.assertFalse(console.runsource("values.append(1)"))
        self.assertEqual(values, [1])
        self.assertEqual(vars(console)["last_buffer"], [b"values.append(1)"])
        self.assertTrue(console.runsource("if True:"))

    def test_failed_editor_cleans_up_buffer(self) -> None:
        console = self.console()
        error = subprocess.CalledProcessError(1, "editor")
        with (
            patch("builtins.input", return_value=r"\e"),
            patch("subprocess.run", side_effect=error) as editor,
            self.assertRaises(subprocess.CalledProcessError),
        ):
            console.raw_input()
        argv = editor.call_args.args[0]
        self.assertEqual(argv[:2], ["editor", "--wait"])
        self.assertFalse(Path(argv[-1]).exists())


class StartupProcessTests(unittest.TestCase):
    """Exercise real readline history, Python display, and external editing."""

    def run_console(self, commands: str, editor: str = "") -> tuple[str, str]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache = root / "cache"
            cache.mkdir()
            temporary = root / "temporary files"
            temporary.mkdir()
            history = cache / ".pyhistory"
            history.write_text("previous\n", encoding="utf-8")
            env = os.environ | {
                "HOME": directory,
                "XDG_CACHE_HOME": str(cache),
                "TMPDIR": str(temporary),
                "TERM": "dumb",
                "EDITOR": editor,
            }
            result = subprocess.run(
                [sys.executable, str(STARTUP)],
                input=commands,
                cwd=root,
                env=env,
                text=True,
                capture_output=True,
                check=False,
                timeout=15,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                result.stderr.strip(),
                (
                    "You've got color, history, and pretty printing.\n"
                    "(If your ~/.inputrc doesn't suck, you've also\n"
                    "got completion and vi-mode keybindings.)\n\n"
                    "Type \\e to get an external editor.\n\n\n"
                    "now exiting EditableBufferInteractiveConsole..."
                ),
            )
            self.assertEqual(list(temporary.iterdir()), [])
            return result.stdout.replace("❯❯❯ ", ""), history.read_text(
                encoding="utf-8"
            )

    def test_history_and_pretty_printing(self) -> None:
        output, history = self.run_console(
            'print(readline.get_history_item(1))\nreadline.add_history("saved")\n'
            '{"answer": 42}\nNone\n_\n'
        )
        self.assertEqual(
            output,
            "previous\n{'answer': 42}\n{'answer': 42}\n\n"
            "Sheesh, I thought he'd never leave. Who invited that guy?\n",
        )
        self.assertEqual(history, "previous\nsaved\n")

    def test_real_editor_handles_temp_paths_with_spaces(self) -> None:
        editor = shutil.which("ex")
        if editor is None:
            self.fail("ex must be installed for the real-editor E2E test")
        command = shlex.join([
            editor,
            "-u",
            "NONE",
            "-i",
            "NONE",
            "-n",
            "-s",
            "-c",
            "%s/1 + 1/40 + 2/",
            "-c",
            "wq",
        ])
        output, _ = self.run_console("1 + 1\n\\e\n_\n", command)
        self.assertEqual(
            output,
            "2\n42\n42\n\nSheesh, I thought he'd never leave. Who invited that guy?\n",
        )


if __name__ == "__main__":
    unittest.main()
