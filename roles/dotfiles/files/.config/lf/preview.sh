#!/usr/bin/env bash

FILE="$1"
HEIGHT="$2"

# [TODO]: figure out how to avoid hard-coding this; (`tput cols` always returns 80)
WIDTH=80

case $(file --brief --mime-type "$FILE") in
image/*)
  chafa --fill=block --symbols=block --colors=256 --size="$WIDTH"x"$HEIGHT" "$FILE"
  ;;
text/* | application/json)
  # https://github.com/gokcehan/lf/issues/234#issuecomment-547592685
  unset COLORTERM
  bat --style=numbers,changes --wrap never --color always "$FILE"
  ;;
application/zip)
  unzip -l "$FILE"
  ;;
application/x-tar | application/gzip)
  tar tf "$FILE"
  ;;
*)
  file --brief "$FILE"
  ;;
esac
