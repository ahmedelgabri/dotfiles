#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

parse() {
	# shellcheck disable=SC2016 # Arguments expand in the child shell.
	env -u TERM bash -c '
		source "$1/scripts/utils"
		shift
		parse_bootstrap_args "$@"
		printf "%s\n" "$FLAKE"
	' bash "$ROOT" "$@"
}

expect_host() {
	local expected=$1 actual
	shift
	actual=$(parse "$@")
	[[ "$actual" == "$expected" ]] || {
		printf 'Expected %s, got %s\n' "$expected" "$actual" >&2
		exit 1
	}
}

expect_error() {
	local expected=$1 actual status=0
	shift
	actual=$(parse "$@" 2>&1) || status=$?
	[[ "$status" == 64 && "$actual" == "$expected" ]] || {
		printf 'Expected error 64 (%s), got %s (%s)\n' "$expected" "$status" "$actual" >&2
		exit 1
	}
}

expect_host "$(hostname -s)"
expect_host alcantara alcantara
expect_host alcantara-without-pragmatapro alcantara --without-pragmatapro
expect_host alcantara-without-pragmatapro --without-pragmatapro alcantara
expect_host "$(hostname -s)-without-pragmatapro" --without-pragmatapro
expect_host rocket-without-pragmatapro rocket --without-pragmatapro --without-pragmatapro
expect_host nixos-without-pragmatapro nixos --without-pragmatapro
expect_host alcantara alcantara
expect_error 'Unknown bootstrap option: --unknown' --unknown
expect_error 'Expected at most one host, got: rocket' alcantara rocket
[[ "$(parse --help)" == 'Usage: bootstrap [host] [--without-pragmatapro]' ]]
[[ "$(parse -h)" == 'Usage: bootstrap [host] [--without-pragmatapro]' ]]
for script in aarch64-darwin_bootstrap x86_64-linux_bootstrap; do
	# shellcheck disable=SC2016 # Arguments expand in the child shell.
	help=$(env -u TERM bash -c 'source "$1/scripts/utils"; source "$1/scripts/$2" --help' bash "$ROOT" "$script")
	[[ "$help" == 'Usage: bootstrap [host] [--without-pragmatapro]' ]]
done
printf 'Bootstrap argument checks passed.\n'
