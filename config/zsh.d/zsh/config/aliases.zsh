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
alias cask="brew --cask "
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
# https://github.com/kovidgoyal/kitty/issues/3936
alias kitty='SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" kitty '

(( $+commands[htop] )) && alias top=htop

if (( $+commands[eza] )); then
  alias ls="eza "
  alias ll='eza --tree --group-directories-first -I "node_modules" '
elif (( $+commands[tree] )); then
  alias ll="type tree >/dev/null && tree --dirsfirst -a -L 1 || l -d .*/ */ "
  alias tree='tree -I  "node_modules" '
else
  alias ll="echo 'You have to install eza or tree'"
fi

if (( $+commands[jq] )) then;
  alias formatJSON='jq .'
else
  alias formatJSON='python -m json.tool'
fi

(( $+commands[bat] )) && alias cat='bat '
(( $+commands[fd] )) && alias fd='fd --hidden '
(( $+commands[yarn] )) && alias y=yarn

if [[ "$(uname)" == linux* ]]; then
  alias chmod='chmod --preserve-root -v'
  alias chown='chown --preserve-root -v'
fi

# https://github.com/neomutt/neomutt/issues/4058#issuecomment-1751682305
alias neomutt="TERM=xterm-direct neomutt"
# https://github.com/direnv/direnv/wiki/Tmux
alias tmux='direnv exec / tmux'
