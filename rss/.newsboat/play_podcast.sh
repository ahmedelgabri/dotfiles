#!/bin/bash

if ! command -v vlc >/dev/null; then
  vlc `cat ~/.newsboat/queue`
else
  open $(cat ~/.newsboat/queue | awk '{ print $1; }')
fi
cat /dev/null > ~/.newsboat/queue
