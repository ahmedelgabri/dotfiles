# vim:ft=zsh:
# setopt warn_create_global

##############################################################
# Profiling.
##############################################################

# Start profiling (uncomment when necessary)
#
# See: https://stackoverflow.com/a/4351664/2103996

# Per-command profiling:

# zmodload zsh/datetime
# setopt promptsubst
# PS4='+$EPOCHREALTIME %N:%i> '
# # More human readable
# PS4=$'%D{%S.%.} %N:%i> '
# exec 3>&2 2> startlog.$$
# setopt xtrace prompt_subst

# Per-function profiling:

# zmodload zsh/zprof

# Must be here because nix-darwin defaults are set in zshrc https://github.com/LnL7/nix-darwin/blob/bd7d1e3912d40f799c5c0f7e5820ec950f1e0b3d/modules/programs/zsh/default.nix#L174-L177
export HISTSIZE=1000000
export SAVEHIST="$HISTSIZE"
export HISTFILE="${XDG_DATA_HOME}/.zsh_history"

############### Misc
eval "$(direnv hook zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(zoxide init zsh --hook pwd)"

##############################################################
# LOCAL.
##############################################################

if [ -f $HOST_CONFIGS/zshrc ]; then
	source $HOST_CONFIGS/zshrc
fi

#
# End profiling (uncomment when necessary)
#

# Per-command profiling:

# unsetopt xtrace
# exec 2>&3 3>&-

# Per-function profiling:

# zprof
