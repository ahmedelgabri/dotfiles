# vim:ft=zsh:

# Useful
alias cp="${aliases[cp]:-cp} -iv"
alias ln="${aliases[ln]:-ln} -iv"
alias mv="${aliases[mv]:-mv} -iv"
alias rm="${aliases[rm]:-rm} -i"
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias e="${(z)VISUAL:-${(z)EDITOR}}"
alias type='type -a'
alias which='which -a'
alias history='fc -il 1'
(( $+commands[htop] )) && alias top=htop


if (( $+commands[exa] )); then
  alias ls="exa "
  alias ll="exa --tree --group-directories-first"
elif (( $+commands[tree] )); then
  alias ll="type tree >/dev/null && tree --dirsfirst -a -L 1 || l -d .*/ */ "
else
  alias ll="echo 'You have to install exa or tree'"
fi

# TERMINAL
alias "?"="pwd"
alias c="clear "
alias KABOOM="yarn global upgrade --latest;brew update; brew upgrade; brew cleanup -s; brew doctor"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes;sudo rm -rfv ~/.Trash"
alias fs="stat -f '%z bytes'"
alias flushdns="sudo killall -HUP mDNSResponder"
if (( $+commands[jq] )) then;
  alias formatJSON='jq .'
else
  alias formatJSON='python -m json.tool'
fi
alias play='mx ϟ'
alias cask="brew cask"
alias apache="sudo apachectl "
alias jobs="jobs -l "

(( $+commands[bat] )) && alias cat='bat '
(( $+commands[python3] )) && alias server="python3 -m http.server 80"
(( $+commands[fd] )) && alias fd='fd --hidden '
(( $+commands[yarn] )) && alias y=yarn

[[ -x "/Applications/Alacritty.app/Contents/MacOS/alacritty" ]] && alias alacritty='/Applications/Alacritty.app/Contents/MacOS/alacritty'
