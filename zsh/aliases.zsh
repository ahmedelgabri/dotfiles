# vim:ft=zsh:
# TERMINAL
alias vi="/usr/local/bin/vim "
alias ev="e ~/.dotfiles/neovim/.config/nvim/init.vim"
alias "?"="pwd"
alias c="clear "
alias ll="type tree >/dev/null && tree -da -L 1 || l -d .*/ */ "
alias lc="ls -AlCF "
alias KABOOM="(npm cache clean; npm update -g) & (brew update && brew reinstall --HEAD neovim && brew upgrade && brew cleanup -s --force && brew prune && brew cask cleanup && brew doctor); source ~/.zshrc"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles true && killall Finder"
alias hidehidden="defaults write com.apple.finder AppleShowAllFiles false && killall Finder"
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"
alias fs="stat -f '%z bytes'"
alias flushdns="sudo killall -HUP mDNSResponder"
alias formatJSON='python -m json.tool'
alias ff='ag --nobreak --nonumbers --noheading . | fzf'
alias dots="cd ~/.dotfiles"
alias work='mx lightspeed lightspeed'
alias play='mx 🤔'
alias cask="brew cask "

# DEV
alias npmls="npm list --depth=0 "
alias apache="sudo apachectl "

# Conditional aliases
# https://gist.github.com/sos4nt/3187620#gistcomment-1452131
[[ $TERM == *"tmux"* ]] && alias ssh="TERM=xterm-256color ssh"
[[ $TERM == *"tmux"* ]] && alias vagrant="TERM=xterm-256color vagrant"
[[ $TERM == *"tmux"* ]] && alias brew="TERM=xterm-256color brew"

command -v nvim >/dev/null && alias vim="nvim "
command -v task >/dev/null && alias t='task'
command -v npm >/dev/null && alias n="npm run "
command -v yarn >/dev/null && alias y="yarn run "
command -v colourify >/dev/null && alias curl='colourify curl '

