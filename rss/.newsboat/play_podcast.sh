#!/bin/bash

if ! command -v mpv >/dev/null; then
  mpv $(command cat ~/.newsboat/queue | awk '{ print $1; }')
else
  open $(command cat ~/.newsboat/queue | awk '{ print $1; }')
fi

command cat /dev/null > ~/.newsboat/queue
