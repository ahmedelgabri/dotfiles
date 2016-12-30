# vim:ft=zsh:
#
# Executes commands at the start of an interactive session.
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# Prezto module overrides.
##############################################################
# Make some commands not show up in history
HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
HISTSIZE=100000
SAVEHIST=$HISTSIZE

##############################################################
# CONFIG.
##############################################################

for config (~/.dotfiles/zsh/config/*.zsh) source $config
for func (~/.dotfiles/zsh/config/functions/*.zsh) source $func

##############################################################
# TOOLS.
##############################################################

command -v grc >/dev/null && source "`brew --prefix`/etc/grc.bashrc"
[ -s "`brew --prefix z`/etc/profile.d/z.sh" ] && source "`brew --prefix z`/etc/profile.d/z.sh"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##############################################################
# LOCAL.
##############################################################

[ -f ~/.zstuff ] && source ~/.zstuff
