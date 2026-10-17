#!/bin/sh
#
# Thin wrapper around the canonical implementation that ships with the
# shannon nvim plugin. Kept here so that the SKILL.md path
# `scripts/shannon-find-nvim.sh` continues to resolve.
#
# Requires shannon to be installed by vim.pack, which keeps plugins under
# stdpath("data")/site/pack/core/opt.

set -eu

CANONICAL="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/core/opt/shannon/bin/find-nvim-socket"

if [ ! -x "$CANONICAL" ]; then
	echo "error: shannon's find-nvim-socket not found at $CANONICAL" >&2
	echo "       (the wincent/shannon nvim plugin must be installed)" >&2
	exit 1
fi

exec "$CANONICAL" "$@"
