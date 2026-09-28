# -*- coding: utf-8 -*-
""".pythonrc for history/completion helpers.

This file is executed when the Python interactive shell is started if
$PYTHONSTARTUP is in your environment and points to this file. It's just
regular Python commands, so do what you will. Your ~/.inputrc file can greatly
complement this file.

"""
# original https://github.com/whiteinge/dotfiles/blob/master/.pythonrc.py

# Imports we need
import atexit
import builtins
import os
import pathlib
import readline
import shlex
import subprocess  # ruff: ignore[suspicious-subprocess-import] -- Launch the user's configured editor.
import sys
from code import InteractiveConsole
from collections import UserDict
from pprint import pprint
from tempfile import TemporaryDirectory
from typing import override

# Imports we want


# Color Support
###############


class TermColors(UserDict[str, str]):
    """Give easy access to ANSI color codes.

    Fall back to no color for unsupported TERM values. Mostly stolen from IPython.
    """

    COLOR_TEMPLATES = (
        ("Black", "0;30"),
        ("Red", "0;31"),
        ("Green", "0;32"),
        ("Brown", "0;33"),
        ("Blue", "0;34"),
        ("Purple", "0;35"),
        ("Cyan", "0;36"),
        ("LightGray", "0;37"),
        ("DarkGray", "1;30"),
        ("LightRed", "1;31"),
        ("LightGreen", "1;32"),
        ("Yellow", "1;33"),
        ("LightBlue", "1;34"),
        ("LightPurple", "1;35"),
        ("LightCyan", "1;36"),
        ("White", "1;37"),
        ("Normal", "0"),
    )

    NoColor = ""
    _base = "\001\033[%sm\002"

    def __init__(self) -> None:
        """Avoid emitting ANSI codes when terminal capabilities are unknown."""
        super().__init__()
        if os.environ.get("TERM") in {
            "xterm-color",
            "xterm-kitty",
            "alacritty",
            "alacritty-direct",
            "xterm-256color",
            "linux",
            "screen",
            "screen-256color",
            "screen-bce",
            "tmux-256color",
        }:
            self.update({k: self._base % v for k, v in self.COLOR_TEMPLATES})
        else:
            self.update({k: self.NoColor for k, _ in self.COLOR_TEMPLATES})


_c = TermColors()

# Enable a History
##################

HISTFILE = f"""{os.environ["XDG_CACHE_HOME"]}/.pyhistory"""

# Read the existing history if there is one
if pathlib.Path(HISTFILE).exists():
    readline.read_history_file(HISTFILE)

# Set maximum number of items that will be written to the history file
readline.set_history_length(1000)


def savehist() -> None:
    """Keep readline history available to the next console session."""
    readline.write_history_file(HISTFILE)


readline.parse_and_bind("tab: complete")
atexit.register(savehist)

# Enable Color Prompts
######################

sys.ps1 = f"""{_c["Red"]}❯{_c["Yellow"]}❯{_c["Green"]}❯ {_c["Normal"]}"""
sys.ps2 = f"""{_c["Red"]}... {_c["Normal"]}"""

# Enable Pretty Printing for stdout
###################################


def my_displayhook(value: object) -> None:
    """Preserve the REPL's last-result binding while pretty-printing values."""
    if value is not None:
        vars(builtins)["_"] = value
        pprint(value)  # ruff: ignore[p-print] -- This is the REPL's display hook.


sys.displayhook = my_displayhook

# Welcome message
#################

WELCOME = f"""\
{_c["Cyan"]}
You've got color, history, and pretty printing.
(If your ~/.inputrc doesn't suck, you've also
got completion and vi-mode keybindings.)
{_c["Brown"]}
Type \\e to get an external editor.
{_c["Normal"]}"""

atexit.register(
    lambda: sys.stdout.write(
        f"""{_c["DarkGray"]}
Sheesh, I thought he'd never leave. Who invited that guy?
{_c["Normal"]}"""
    )
)

# Start an external editor with \e
##################################
# http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/438813/

EDITOR = os.environ.get("EDITOR", "vi")
EDIT_CMD = r"\e"


class EditableBufferInteractiveConsole(InteractiveConsole):
    """Allow the previous input to be revised in the user's preferred editor."""

    def __init__(
        self,
        # Keep the standard library constructor's keyword argument name.
        locals: dict[str, object] | None = None,  # ruff: ignore[builtin-argument-shadowing]
        filename: str = "<console>",
        *,
        local_exit: bool = False,
    ) -> None:
        """Retain compiler state and a separate editable copy of the last input."""
        self.last_buffer: list[bytes] = []  # This holds the last executed statement
        super().__init__(locals=locals, filename=filename, local_exit=local_exit)

    @override
    def runsource(
        self,
        source: str,
        filename: str = "<input>",
        symbol: str = "single",
    ) -> bool:
        """Remember source before compilation so incomplete input can be edited.

        Returns:
            Whether the compiler needs more input.

        """
        self.last_buffer = [source.encode("utf-8")]
        return super().runsource(source, filename, symbol)

    @override
    def raw_input(self, prompt: str = "") -> str:
        """Treat the editor command as a request to revise the previous buffer.

        Returns:
            The next line for the interactive compiler.

        """
        line = super().raw_input(prompt)
        if line == EDIT_CMD:
            with TemporaryDirectory() as directory:
                buffer = pathlib.Path(directory) / "buffer.py"
                buffer.write_bytes(b"\n".join(self.last_buffer))
                # EDITOR is user-configured; the buffer path must stay one argument.
                subprocess.run(  # ruff: ignore[subprocess-without-shell-equals-true]
                    [*shlex.split(EDITOR), str(buffer)], check=True
                )
                line = buffer.read_text(encoding="utf-8")
            lines = line.split("\n")
            for i in range(len(lines) - 1):
                self.push(lines[i])
            line = lines[-1]
        return line


c = EditableBufferInteractiveConsole(locals=locals())
c.interact(banner=WELCOME)

# Exit the Python shell on exiting the InteractiveConsole
sys.exit()
