#!/usr/bin/env python

import re
import socket

HOST = socket.gethostname()

if re.search(r"\__CHANGE_ME__\b", HOST):
    GROUP = "work"
elif re.match(r"pandoras-box(?:\.(?:local|lan)?)?\Z", HOST):
    GROUP = "personal"
else:
    GROUP = "local"

print(
    """
{
  "%s": {
    "hosts": [
      "localhost"
    ],
    "vars": {
      "ansible_connection": "local"
    }
  }
}
"""
    % GROUP
)
