# vim:ft=zsh:foldmethod=marker:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# ZPLUGIN https://github.com/zdharma/zplugin
##############################################################

if [[ ! -f ~/.zplugin/bin/zplugin.zsh ]]; then
  if (( $+commands[git] )); then
    git clone https://github.com/zdharma/zplugin.git ~/.zplugin/bin
  else
    echo 'git not found' >&2
    exit 1
  fi
fi

source ~/.zplugin/bin/zplugin.zsh

# Shell {{{
  zplugin light zdharma/zui
  zplugin ice lucid wait'[[ -n ${ZLAST_COMMANDS[(r)cras*]} ]]'
  zplugin light zdharma/zplugin-crasis

  zplugin ice pick"async.zsh" src"pure.zsh"
  zplugin light ahmedelgabri/pure
# }}}

# Tools {{{
  zplugin ice as"program" pick"transcrypt"
  zplugin light elasticdog/transcrypt

  zplugin ice from"gh-r" as"program" mv"direnv* -> direnv" atload'export NODE_VERSIONS="${HOME}/.node-versions"; export NODE_VERSION_PREFIX=""; eval "$(direnv hook zsh)"';
  zplugin light direnv/direnv

  zplugin ice as"program" atclone"./install --bin" atpull"%atclone" atload'local f; for f (shell/*.zsh) source $f' compile"shell/*.zsh" pick"bin/*"
  zplugin light junegunn/fzf
# }}}

# Git {{{
  zplugin ice as'program' make"install prefix=$ZPFX" pick"$ZPFX/bin/tig"
  zplugin light jonas/tig

  zplugin ice as"program" pick"bin/git-dsf"
  zplugin light zdharma/zsh-diff-so-fancy
# }}}

# Utilities & enhancements {{{
  zplugin ice as"program" atclone"./install.sh $ZPFX $ZPFX" atpull"%atclone" compile"grc.zsh" src"grc.zsh" pick"$ZPFX/bin/grc*"
  zplugin light garabik/grc

  zplugin ice from"gh-r" as"program" mv"fd*/fd -> fd"
  zplugin light sharkdp/fd

  zplugin ice from"gh-r" as"program" bpick"*osx*" mv"jq* -> jq"
  zplugin light stedolan/jq

  zplugin ice from"gh-r" as"program" bpick"*macos*" mv"exa* -> exa"
  zplugin light ogham/exa

  zplugin ice from"gh-r" as"program" mv"bat*/bat -> bat"
  zplugin light sharkdp/bat

  zplugin ice as"program" make"install PREFIX=$ZPFX" pick"$ZPFX/bin/trans"
  zplugin light soimort/translate-shell

  zplugin ice as"program" mv"rename"
  zplugin light ap/rename

  zplugin ice pick"z.sh"
  zplugin light rupa/z

  zplugin light "zsh-users/zsh-history-substring-search"

  # https://github.com/zdharma/zplugin#turbo-mode-zsh--53
  zplugin ice wait"1" lucid atload"_zsh_autosuggest_start"
  zplugin light zsh-users/zsh-autosuggestions

  zplugin ice wait"0" blockf lucid
  zplugin light zsh-users/zsh-completions

  zplugin ice wait"0" lucid atinit"zpcompinit; zpcdreplay"
  zplugin light zdharma/fast-syntax-highlighting
# }}}

# UI {{{
  zplugin ice from"gh-r" bpick"*ss08*" atclone'local f; for f (ttf/*.ttf); [ -f "~/Library/Fonts/$(basename $f)" ] && rm "~/Library/Fonts/$(basename $f)" && mv $f ~/Library/Fonts/ || mv $f ~/Library/Fonts/' atpull"%atclone"
  zplugin light be5invis/Iosevka
# }}}

##############################################################
# PLUGINS VARS & SETTINGS
##############################################################

ZSH_AUTOSUGGEST_USE_ASYNC=true

# bind UP and DOWN keys
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# bind UP and DOWN arrow keys (compatibility fallback)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

##############################################################
# CONFIG.
##############################################################

source ${ZDOTDIR}/rc.d/aliases.zsh
for func (${ZDOTDIR}/rc.d/functions/*.zsh) source $func

##############################################################
# Custom/Plugins
###############################################################
export RIPGREP_CONFIG_PATH="$DOTFILES/misc/.rgrc"
export FZF_DEFAULT_OPTS='--min-height 30 --height 50% --reverse --tabstop 2 --multi --margin 0,3,3,3 --preview-window wrap'
export FZF_DEFAULT_COMMAND='rg --no-messages --no-ignore-vcs --files'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview "(highlight -O ansi -l {} || cat {} || tree -C {}) 2> /dev/null | head -200" --bind "?:toggle-preview"'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_VIM_LOG=$(git config --get alias.l | awk '{$1=""; print $0;}' | tr -d '\r')

export HOMEBREW_INSTALL_BADGE="⚽️"
export HOMEBREW_NO_ANALYTICS=1
export WEECHAT_PASSPHRASE=`security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`
# `cd ~df` or `z ~df`
# hash -d df=~/.dotfiles

SYMBOLS=(
"λ"
"ϟ"
"▲"
"∴"
"→"
"»"
"৸"
)

# Arrays in zsh starts from 1
export PURE_PROMPT_SYMBOL="${SYMBOLS[$RANDOM % ${#SYMBOLS[@]} + 1]}"
[ -n "$NERD_FONTS" ] && export PURE_GIT_BRANCH=" " || export PURE_GIT_BRANCH=" "

##############################################################
# Python
###############################################################

export PYTHONSTARTUP=${HOME}/.pyrc.py

# di directories
# ex executable files
# fi regular files
# ln symlinks
# ur,uw,ux user permissions
# gr,gw,gx group permissions
# tr,tw,tx others permissions
# sn the numbers of a file's size
# sb the units of a file's size
# uu user that is you
# un user that is someone else
# gu a group that you belong to
# gn a group you aren't a member of
# ga new file in Git
# gm a modified file in Git
# gd a deleted file in Git
# gv a renamed file in Git
# da a file's date
export EXA_COLORS="uu=38;5;249:un=38;5;241:gu=38;5;245:gn=38;5;241:da=38;5;245:sn=38;5;7:sb=38;5;7:ur=38;5;3;1:uw=38;5;5;1:ux=38;5;1;1:ue=38;5;1;1:gr=38;5;3:gw=38;5;5:gx=38;5;1:tr=38;5;3:tw=38;5;1:tx=38;5;1:di=38;5;12:ex=38;5;7;1:*.md=38;5;229;4:*.png=38;5;208:*.jpg=38;5;208:*.gif=38;5;208"

##############################################################
# /etc/motd
##############################################################

if [ -e /etc/motd ]; then
  if ! cmp -s ${HOME}/.hushlogin /etc/motd; then
    tee ${HOME}/.hushlogin < /etc/motd
  fi
fi

##############################################################
# Custom completions init.
##############################################################

[ -f ${ZDOTDIR:-${HOME}}/rc.d/completions/init.zsh ] && source ${ZDOTDIR:-${HOME}}/rc.d/completions/init.zsh

##############################################################
# LOCAL.
##############################################################

if [ -f ${HOME}/.zshrc.local ]; then
  source ${HOME}/.zshrc.local
else
  if [[ -z "${HOMEBREW_GITHUB_API_TOKEN}" && -z "${GITHUB_TOKEN}" && -z "${GITHUB_USER}" ]]; then
    echo "These ENV vars are not set: HOMEBREW_GITHUB_API_TOKEN, GITHUB_TOKEN & GITHUB_USER. Add them to ~/.zshrc.local"
  fi
fi
