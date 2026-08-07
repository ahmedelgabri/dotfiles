# -*- coding: utf-8 -*-
""".pythonrc for history/completion helpers

This file is executed when the Python interactive shell is started if
$PYTHONSTARTUP is in your environment and points to this file. It's just
regular Python commands, so do what you will. Your ~/.inputrc file can greatly
complement this file.

"""
# original https://github.com/whiteinge/dotfiles/blob/master/.pythonrc.py

# Imports we need
import sys
import os
import readline
import atexit
from pprint import pprint
from tempfile import mkstemp
from code import InteractiveConsole

# Imports we want


# Color Support
###############


class TermColors(dict):
    """Gives easy access to ANSI color codes. Attempts to fall back to no color
    for certain TERM values. (Mostly stolen from IPython.)"""

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

    def __init__(self):
        if os.environ.get("TERM") in (
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
        ):
            self.update(dict([(k, self._base % v) for k, v in self.COLOR_TEMPLATES]))
        else:
            self.update(dict([(k, self.NoColor) for k, v in self.COLOR_TEMPLATES]))


_c = TermColors()

# Enable a History
##################

HISTFILE = f"""{os.environ["XDG_CACHE_HOME"]}/.pyhistory"""

# Read the existing history if there is one
if os.path.exists(HISTFILE):
    readline.read_history_file(HISTFILE)

# Set maximum number of items that will be written to the history file
readline.set_history_length(1000)


def savehist():
    readline.write_history_file(HISTFILE)


readline.parse_and_bind("tab: complete")
atexit.register(savehist)

# Enable Color Prompts
######################

sys.ps1 = f"""{_c["Red"]}❯{_c["Yellow"]}❯{_c["Green"]}❯ {_c["Normal"]}"""
sys.ps2 = f"""{_c["Red"]}... {_c["Normal"]}"""

# Enable Pretty Printing for stdout
###################################


def my_displayhook(value):
    if value is not None:
        try:
            import __builtin__

            __builtin__._ = value
        except ImportError:
            __builtins__._ = value

        pprint(value)


sys.displayhook = my_displayhook

# Welcome message
#################

WELCOME = (
    """\
%(Cyan)s
You've got color, history, and pretty printing.
(If your ~/.inputrc doesn't suck, you've also
got completion and vi-mode keybindings.)
%(Brown)s
Type \e to get an external editor.
%(Normal)s"""
    % _c
)

atexit.register(
    lambda: sys.stdout.write(
        """%(DarkGray)s
Sheesh, I thought he'd never leave. Who invited that guy?
%(Normal)s"""
        % _c
    )
)

# Start an external editor with \e
##################################
# http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/438813/

EDITOR = os.environ.get("EDITOR", "vi")
EDIT_CMD = r"\e"


class EditableBufferInteractiveConsole(InteractiveConsole):
    def __init__(self, *args, **kwargs):
        self.last_buffer = []  # This holds the last executed statement
        InteractiveConsole.__init__(self, *args, **kwargs)

    def runsource(self, source, *args, **kwargs):
        self.last_buffer = [source.encode("utf-8")]
        return InteractiveConsole.runsource(self, source, *args, **kwargs)

    def raw_input(self, *args):
        line = InteractiveConsole.raw_input(self, *args)
        if line == EDIT_CMD:
            fd, tmpfl = mkstemp(".py")
            os.write(fd, b"\n".join(self.last_buffer))
            os.close(fd)
            os.system("%s %s" % (EDITOR, tmpfl))
            line = open(tmpfl).read()
            os.unlink(tmpfl)
            tmpfl = ""
            lines = line.split("\n")
            for i in range(len(lines) - 1):
                self.push(lines[i])
            line = lines[-1]
        return line


c = EditableBufferInteractiveConsole(locals=locals())
c.interact(banner=WELCOME)

# Exit the Python shell on exiting the InteractiveConsole
sys.exit()
