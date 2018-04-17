# vim:ft=zsh:

# Useful
alias cp="${aliases[cp]:-cp} -i"
alias e="${(z)VISUAL:-${(z)EDITOR}}"
alias ln="${aliases[ln]:-ln} -i"
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias mv="${aliases[mv]:-mv} -i"
alias rm="${aliases[rm]:-rm} -i"
alias type='type -a'

if (( $+commands[htop] )); then
  alias top=htop
fi


if (( $+commands[exa] )); then
  alias ll="exa --tree"
elif (( $+commands[tree] )); then
  alias ll="type tree >/dev/null && tree -da -L 1 || l -d .*/ */ "
else
  alias ll="echo 'You have to install exa or tree'"
fi

# TERMINAL
alias "?"="pwd"
alias c="clear "
alias KABOOM="yarn global upgrade --latest; brew update; brew upgrade; brew cleanup -s --force; brew prune; brew cask cleanup; brew doctor"
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias fs="stat -f '%z bytes'"
alias flushdns="sudo killall -HUP mDNSResponder"
alias listPath='echo $PATH | tr -s ":" "\n" '
if (( $+commands[jq] )) then;
  alias formatJSON='jq .'
else
  alias formatJSON='python -m json.tool'
fi
alias dots="cd $DOTFILES"
alias work='mx lightspeed lightspeed'
alias play='mx ϟ'
alias cask="brew cask"
alias apache="sudo apachectl "

[[ $TERM == *"tmux"* ]] && alias :sp='tmux split-window'
[[ $TERM == *"tmux"* ]] && alias :vs='tmux split-window -h'

# Conditional aliases
# https://gist.github.com/sos4nt/3187620#gistcomment-1452131
[[ $TERM == *"tmux"* ]] && alias ssh="TERM=xterm-256color ssh"
[[ $TERM == *"tmux"* ]] && alias vagrant="TERM=xterm-256color vagrant"
[[ $TERM == *"tmux"* ]] && alias brew="TERM=xterm-256color brew"

(( $+commands[rg] )) && alias rg="rg --hidden "
(( $+commands[emacs] )) && alias emacs="TERM=xterm-256color emacs "
(( $+commands[task] )) && alias t='task'
(( $+commands[colourify] )) && alias curl='colourify curl '
(( $+commands[stow] )) && alias stow='stow --ignore ".DS_Store"'
