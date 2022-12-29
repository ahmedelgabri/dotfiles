# -*- coding: utf-8 -*-
""".pythonrc for history/completion & Django dev

This file is executed when the Python interactive shell is started if
$PYTHONSTARTUP is in your environment and points to this file. It's just
regular Python commands, so do what you will. Your ~/.inputrc file can greatly
complement this file.

"""
# original https://github.com/whiteinge/dotfiles/blob/master/.pythonrc.py

# Imports we need
import sys
import os
import re
import readline, rlcompleter
import atexit
from pprint import pprint
from tempfile import mkstemp
from code import InteractiveConsole

# Imports we want
import datetime
import pdb


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

# Django Helpers
################


def SECRET_KEY():
    "Generates a new SECRET_KEY that can be used in a project settings file."

    from random import choice

    return "".join(
        [
            choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)")
            for i in range(50)
        ]
    )


# If we're working with a Django project, set up the environment
if "DJANGO_SETTINGS_MODULE" in os.environ:
    from django.db.models.loading import get_models
    from django.test.client import Client
    from django.test.utils import setup_test_environment, teardown_test_environment
    from django.conf import settings as S

    class DjangoModels(object):
        """Loop through all the models in INSTALLED_APPS and import them."""

        def __init__(self):
            for m in get_models():
                setattr(self, m.__name__, m)

    A = DjangoModels()
    C = Client()

    WELCOME += (
        """%(Green)s
Django environment detected.
* Your INSTALLED_APPS models are available as `A`.
* Your project settings are available as `S`.
* The Django test client is available as `C`.
%(Normal)s"""
        % _c
    )

    setup_test_environment()
    S.DEBUG_PROPAGATE_EXCEPTIONS = True

    WELCOME += (
        """%(LightPurple)s
Warning: the Django test environment has been set up; to restore the
normal environment call `teardown_test_environment()`.

Warning: DEBUG_PROPAGATE_EXCEPTIONS has been set to True.
%(Normal)s"""
        % _c
    )


# Salt Helpers
##############
if "SALT_CLIENT_CONFIG" in os.environ:
    try:
        import salt.config
        import salt.client
        import salt.runner
    except ImportError:
        pass
    else:
        __opts_client__ = salt.config.client_config(os.environ["SALT_CLIENT_CONFIG"])

        # Instantiate LocalClient and RunnerClient
        SLC = salt.client.LocalClient(mopts=__opts_client__)
        SRUN = salt.runner.Runner(__opts_client__)

if "SALT_MINION_CONFIG" in os.environ:
    try:
        import salt.config
        import salt.client
        import salt.loader
        import jinja2
        import yaml
    except ImportError:
        pass
    else:
        # # Create the Salt __opts__ variable
        __opts__ = salt.config.minion_config(os.environ.get("SALT_MINION_CONFIG"))

        # Default to local mode to avoid timeouts if a master is not running.
        # Can set this to 'remote' manually and re-instantiate if desired.
        __opts__["file_client"] = "local"

        # Instantiate the Caller class
        SCALL = salt.client.Caller(mopts=__opts__)

        # Populate grains if it hasn't been done already
        if not "grains" in __opts__ or not __opts__["grains"]:
            __opts__["grains"] = salt.loader.grains(__opts__)

        # Populate template variables
        __salt__ = salt.loader.minion_mods(__opts__)
        __grains__ = __opts__["grains"]

# Start an external editor with \e
##################################
# http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/438813/

EDITOR = os.environ.get("EDITOR", "vi")
EDIT_CMD = r"\e"


class EditableBufferInteractiveConsole(InteractiveConsole):
    def __init__(self, *args, **kwargs):
        self.last_buffer = []  # This holds the last executed statement
        InteractiveConsole.__init__(self, *args, **kwargs)

    def runsource(self, source, *args):
        self.last_buffer = [source.encode("utf-8")]
        return InteractiveConsole.runsource(self, source, *args)

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
