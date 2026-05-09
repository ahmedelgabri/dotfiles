#!/bin/sh
#
# Thin wrapper around the canonical implementation that ships with the
# shannon nvim plugin. Kept here so that the SKILL.md path
# `scripts/shannon-find-nvim.sh` continues to resolve.
#
# Requires shannon to be installed at the standard nvim pack location.

set -eu

CANONICAL="$HOME/.config/nvim/pack/bundle/opt/shannon/bin/find-nvim-socket"

if [ ! -x "$CANONICAL" ]; then
	echo "error: shannon's find-nvim-socket not found at $CANONICAL" >&2
	echo "       (the wincent/shannon nvim plugin must be installed)" >&2
	exit 1
fi

exec "$CANONICAL" "$@"
