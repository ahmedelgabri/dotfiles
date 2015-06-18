# !/usr/bin/env python
# Copyright (c) 2013 Alexandre Gauthier
#
# Some rights reserved.
#
# Redistribution and use in source and binary forms of the software as well
# as documentation, with or without modification, are permitted provided
# that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the following
#   disclaimer in the documentation and/or other materials provided
#   with the distribution.
#
# THIS SOFTWARE AND DOCUMENTATION IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
# NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE AND DOCUMENTATION, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

import os
import re
import sys

# I'm sorry.
try:
    import weechat
except ImportError:
    print "This is a WeeChat Script - http://www.weechat.org"
    print "It makes no sense to run it on its own."
    sys.exit(1)


# Global / Static script values
SCRIPT_NAME = "emojis"
SCRIPT_AUTHOR = "Alexandre Gauthier <alex@underwares.org>"
SCRIPT_VERSION = "0.1"
SCRIPT_LICENSE = "BSD"
SCRIPT_DESCRIPTION = "Allows you to spam emojis based on :triggers:"

# Emojis cache
EMOJIS = {}

# Decode required for proper calculation of string
# length, and to avoid some bugs when concatenating
# unicode/normal strings.
#
# FIXME: I don't like that this is a thing. Weechat supposedly uses
# UTF-8 internally exclusively, i'm not sure why we need to transit
# through ascii.

def decode(s):
    """ Decode utf-8 to ascii """
    if isinstance(s, str):
        s = s.decode('utf-8')
    return s

def encode(u):
    """ Encode ascii as utf-8 """
    if isinstance(u, unicode):
        u = u.encode('utf-8')
    return u

def load_emojis(dbfile):
    """ Load emojis from file """

    global EMOJIS

    with open(dbfile) as f:
        for line in f:
            if line.startswith(':'):
                EMOJIS[line.rstrip()] = f.next().rstrip()
            else:
                weechat.prnt("", "%s%s: Malformed line in %s: %s" \
                    % (weechat.prefix("error"), SCRIPT_NAME, f.name, line))


        weechat.prnt("", "%s: Loaded %d knifaisms." \
            % (SCRIPT_NAME, len(EMOJIS)))

def reload_emojis():
    """ Reload emojis from currently configured database """
    global EMOJIS

    weechat.prnt("", "%s: Reloading emojis from %s" \
            % (SCRIPT_NAME, weechat.config_get_plugin("dbfile")))

    # Clear out emojis before reload.
    EMOJIS = {}

    load_emojis(weechat.config_get_plugin("dbfile"))


def transform_cb(data, bufferptr, command):
    """ Apply transformation to input line in specified buffer """

    if command == "/input return":
        # Get input line from buffer. This is where we'll apply the
        # transformation right when the user hits enter. To be brutally
        # honest, I had no idea how else to make it happen.
        line = weechat.buffer_get_string(bufferptr, 'input')

        # Ignore commands
        if line.startswith('/'):
            return weechat.WEECHAT_RC_OK

        # Apply transforms.
        # This could probably be optimized.
        for key, value in EMOJIS.iteritems():
            if key in line:
                line = line.replace(key, value)

        # Poot transformed line back into buffer's input line.
        weechat.buffer_set(bufferptr, 'input', line)

    return weechat.WEECHAT_RC_OK

def complete_cb(data, bufferptr, command):
    """ Apply transformation to input line in specified buffer """

    if command != "/input complete_next":
        return weechat.WEECHAT_RC_OK

    line = decode(weechat.buffer_get_string(bufferptr, 'input'))
    caret_pos = weechat.buffer_get_integer(bufferptr, 'input_pos')

    match = re.search('(:\w+$)', line[:caret_pos])
    if not match:
        return weechat.WEECHAT_RC_OK

    # tw = tabbed word
    tw = match.group(0)
    tw_length = len(tw)
    tw_start = caret_pos - tw_length
    tw_end = caret_pos

    completion = ""
    for key, value in EMOJIS.iteritems():
        if key.startswith(tw):
            completion = decode(value)
            break

    if completion:
        line = line[:tw_start] + completion + line[tw_end:]
        new_caret_pos = caret_pos - tw_length + len(completion)
        weechat.buffer_set(bufferptr, 'input', encode(line))
        weechat.buffer_set(bufferptr, 'input_pos', str(new_caret_pos))

    return weechat.WEECHAT_RC_OK

def configuration_cb(data, option, value):
    """ Configuration change callback """

    weechat.prnt("", "%s: Configuration change detected." % (SCRIPT_NAME))
    reload_emojis()
    return weechat.WEECHAT_RC_OK

def reload_emojis_cb(data, bufferptr, args):
    """ Command callback wrapper around reload_emojis() """

    reload_emojis()
    return weechat.WEECHAT_RC_OK


def main():
    """ Entry point, initializes everything  """

    weechat.register(
        SCRIPT_NAME,
        SCRIPT_AUTHOR,
        SCRIPT_VERSION,
        SCRIPT_LICENSE,
        SCRIPT_DESCRIPTION,
        "", # Shutdown callback function
        "", # Charset (blank for utf-8)
    )

    # Default values for settings
    default_settings = {
        'dbfile': os.path.join(
            weechat.info_get("weechat_dir", ""), "emojis-db.dat")
    }

    # Apply default configuration values if anything is unset
    for option, default in default_settings.items():
        if not weechat.config_is_set_plugin(option):
            weechat.config_set_plugin(option, default)

    # Hook callbacks
    weechat.hook_config("plugins.var.python." + SCRIPT_NAME + ".*",
        "configuration_cb", "")
    weechat.hook_command_run("/input return", "transform_cb", "")
    weechat.hook_command_run("/input complete*", "complete_cb", "")

    # Command callbacks
    weechat.hook_command("reloademojis", "reload emojis from file",
        "","","", "reload_emojis_cb", "")

    dbfile = weechat.config_get_plugin("dbfile")

    weechat.prnt("", "%s: Loading emojis from %s" % (SCRIPT_NAME, dbfile))

    try:
        load_emojis(dbfile)
    except IOError as e:
        weechat.prnt("",
            "%s%s: Database file %s is missing or inaccessible." \
                    % (weechat.prefix("error"), SCRIPT_NAME, dbfile))
        raise e # TODO: handle this better instead of brutally aborting

if __name__ == '__main__':
    main()

