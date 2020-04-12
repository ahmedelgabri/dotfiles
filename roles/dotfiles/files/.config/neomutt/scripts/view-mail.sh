#!/bin/sh

COLUMNS=${COLUMNS:-`tput cols`}
TMPFILE="$1"
ENCODING="${2:utf-8}"

# Need to copy the file because mutt will delete it before Vim can read it.
DIR=$(mktemp -d)
cp "$TMPFILE" "$DIR/preview"
TMPFILE="$DIR/preview"
PANE=$(tmux display -pt "$TMUX_PANE" '#S:#I.#P')

if [ -z "$TMUX" ]; then
  $EDITOR "+set fileencoding=$ENCODING" '+set filetype=mail' '+set nofoldenable' '+set nomodifiable' '+nmap q :q!<cr>' "$TMPFILE"
elif [ "$COLUMNS" -gt 180 ]; then
  tmux split-pane -t"$PANE" -p 50 -h $EDITOR "+set fileencoding=$ENCODING" '+set filetype=mail' '+set nofoldenable' '+set nomodifiable' '+nmap q :q!<cr>' "$TMPFILE"
else
  tmux split-pane -t"$PANE" -p 50 -v $EDITOR "+set fileencoding=$ENCODING" '+set filetype=mail' '+set nofoldenable' '+set nomodifiable' '+nmap q :q!<cr>' "$TMPFILE"
fi
