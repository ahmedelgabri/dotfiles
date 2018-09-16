#!/bin/bash

if ! command -v vlc >/dev/null; then
  vlc `command cat ~/.newsboat/queue`
else
  open $(command cat ~/.newsboat/queue | awk '{ print $1; }')
fi
command cat /dev/null > ~/.newsboat/queue
