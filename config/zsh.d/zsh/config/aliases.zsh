# vim:ft=zsh:
# Useful
alias cp="${aliases[cp]:-cp} -iv"
alias ln="${aliases[ln]:-ln} -iv"
alias mv="${aliases[mv]:-mv} -iv"
alias rm="${aliases[rm]:-rm} -i"
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias sudo="sudo "
alias type='type -a'
alias c="clear "
alias e='$EDITOR --listen /tmp/nvim.pipe'
alias df="df -kh"
alias du="du -kh"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash"
alias fd="fd --hidden "
alias flushdns="sudo killall -HUP mDNSResponder"
alias fs="stat -f '%z bytes'"
alias history-stat="fc -l 1 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"
alias history='fc -il 1'
alias jobs="jobs -l "
alias play='mx ϟ'
alias y="yarn"
alias p="pnpm"
alias top=htop
alias ls="l"
alias ll='eza --tree --group-directories-first --almost-all -I "node_modules" '
alias formatJSON='jq .'
alias cat='bat '
alias grep='grep --color=auto'
# https://github.com/neomutt/neomutt/issues/4058#issuecomment-1751682305
alias neomutt="TERM=xterm-direct neomutt"

# https://github.com/direnv/direnv/wiki/Tmux
alias tmux='direnv exec / tmux'

if (( ${+commands[wget]} )); then
  alias get='wget --continue --progress=bar --timestamping'
elif (( ${+commands[curl]} )); then
  alias get='curl --continue-at - --location --progress-bar --remote-name --remote-time'
fi

if [[ "$(uname)" == linux* ]]; then
  alias chmod='chmod --preserve-root -v'
  alias chown='chown --preserve-root -v'
fi
