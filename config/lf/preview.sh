#!/usr/bin/env bash

FILE="$1"
HEIGHT="$2"
WIDTH="$4"

case $(file --brief --mime-type "$FILE") in
image/*)
	chafa --fill=block --symbols=block --colors=256 --size="$WIDTH"x"$HEIGHT" "$FILE"
	;;
text/troff)
	man ./ "$1" | col -b
	;;
text/* | */xml | application/json)
	# https://github.com/gokcehan/lf/issues/234#issuecomment-547592685
	unset COLORTERM
	bat --style=numbers,changes --terminal-width "$WIDTH" --wrap never --color always "$FILE"
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
