# git commit browser. needs fzf
log() {
  git log --pretty=format:"%h - (%cr) %s - %an %d" --date=short "$@" |
  fzf --no-sort --reverse --tiebreak=index --toggle-sort=\` \
      --bind "ctrl-m:execute:
                echo '{}' | grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R'"
}
