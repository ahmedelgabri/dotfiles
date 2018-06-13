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
    git status --short --branch
    time_since_last_commit
  fi
}

function time_since_last_commit() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  GIT_INFO_MESSAGE=$(git log -1 --color=always --pretty=format:"%C(blue)%h %Creset- %C(green)(%cr) %Creset%s - %C(cyan)%aN%Creset" --date=relative)
  echo "\n$GIT_INFO_MESSAGE"
}
