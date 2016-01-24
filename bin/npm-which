#!/usr/bin/env zsh

local npm_bin=$(npm bin)
local bin_name=$1
local local_path="${npm_bin}/${bin_name}"

[[ -f $local_path ]] && echo $local_path && return

echo $(which $bin_name)
