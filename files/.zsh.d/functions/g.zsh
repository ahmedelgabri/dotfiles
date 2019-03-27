# https://github.com/pengwynn/dotfiles/blob/master/git/git.zsh
# Wrap git with hub
#
# Hey future self! if you are here because of this error `zsh compinit: insecure directories, run compaudit for list.`
# do the following
# $ cd /usr/local/share/
# $ sudo chmod -R 755 zsh
# $ sudo chown -R $USER:staff zsh

(( $+commands[git] )) || return 0

unalias g 2>/dev/null

if [[ -f `command -v hub` ]] ; then
  alias git=hub
  compdef g=hub
else
  compdef g=git
fi

function g() {
  if [[ $# > 0 ]]; then
    git "$@"
  else
    echo "$(time_since_last_commit)\n"
    git status --short --branch
  fi
}

function time_since_last_commit() {
  local ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  local LAST_COMMIT=$(git log --color=always -n 1 --pretty=format:"%C(green)[%cr]%Creset %C(blue)%h%Creset %s - %C(cyan)%aN%Creset" --date=auto:human 2>/dev/null)

  echo "Last commit:\n$LAST_COMMIT"
}
