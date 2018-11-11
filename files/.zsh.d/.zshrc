# vim:ft=zsh:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# ZPLUGIN https://github.com/zdharma/zplugin
##############################################################

ZPLUGIN="${ZDOTDIR:-$HOME}/.zplugin/bin/zplugin.zsh"

if [[ ! -f "$ZPLUGIN" ]]; then
  if (( $+commands[git] )); then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"
  else
    echo 'git not found' >&2
    exit 1
  fi
fi

source "$ZPLUGIN"
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin

# Shell {{{
  zplugin light zdharma/zui
  zplugin ice lucid wait'[[ -n ${ZLAST_COMMANDS[(r)cras*]} ]]'
  zplugin light zdharma/zplugin-crasis

  zplugin ice pick"async.zsh" src"pure.zsh"
  zplugin light ahmedelgabri/pure
# }}}

# Tools {{{
  zplugin ice from"gh-r" as"program" mv"direnv* -> direnv" atload'export NODE_VERSIONS="${HOME}/.node-versions"; export NODE_VERSION_PREFIX=""; eval "$(direnv hook zsh)"';
  zplugin light direnv/direnv

  zplugin ice as"program" atclone"./install --bin" atpull"%atclone" atload'export FZF_PATH="${ZDOTDIR:-$HOME}/.zplugin/plugins/junegunn---fzf"; local f; for f (shell/*.zsh) source $f' compile"shell/*.zsh" pick"bin/*"
  zplugin light junegunn/fzf

  zplugin ice as"program" atclone"./install.sh $ZPLGM[PLUGINS_DIR]/garabik---grc $ZPLGM[PLUGINS_DIR]/garabik---grc"atpull"%atclone" atload"source grc.zsh" pick"bin/*"
  zplugin light garabik/grc
# }}}

# Utilities & enhancements {{{
  zplugin light "zsh-users/zsh-history-substring-search"

  zplugin ice wait"0" blockf lucid
  zplugin light zsh-users/zsh-completions

  zplugin ice wait"0" lucid atload"_zsh_autosuggest_start"
  zplugin light zsh-users/zsh-autosuggestions

  zplugin ice wait"0" lucid atinit"zpcompinit; zpcdreplay"
  zplugin light zdharma/fast-syntax-highlighting
# }}}

# Misc {{{
  zplugin ice from"gh-r" as"program" bpick"*clojure-lsp*" atclone"chmod 755 clojure-lsp" atpull"%atclone" mv="clojure-lsp -> clojure-lsp"
  zplugin light snoe/clojure-lsp

  zplugin ice id-as"be5invis/Iosevka" from"gh-r" bpick"*01-iosevka*" atclone'local f; for f (ttf/*.ttf); mv -f $f ~/Library/Fonts/' atpull"%atclone"
  zplugin light be5invis/Iosevka

  zplugin ice id-as"be5invis/Iosevka-term" from"gh-r" bpick"*02-iosevka-term*" atclone'local f; for f (ttf/*.ttf); mv -f $f ~/Library/Fonts/' atpull"%atclone"
  zplugin light be5invis/Iosevka
# }}}

# Local plugins/completions/etc... {{{
  zplugin ice lucid atinit'local i; for i in *.zsh; do source $i; done'
  zplugin light %HOME/.zsh.d/functions

  zplugin light %HOME/.zsh.d/aliases

  zplugin creinstall -q %HOME/.zsh.d/completions
# }}}

if [[ ! -z "${KITTY_WINDOW_ID}" ]]; then
  kitty + complete setup zsh | source /dev/stdin
fi

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
# Custom/Plugins
###############################################################
export RIPGREP_CONFIG_PATH="$HOME/.rgrc"
export FZF_CMD='fd --hidden --follow --no-ignore-vcs --exclude ".git/*" --exclude "node_modules/*"'
export FZF_DEFAULT_OPTS='--min-height 30 --height 50% --reverse --tabstop 2 --multi --margin 0,3,3,3 --preview-window wrap'
export FZF_DEFAULT_COMMAND="$FZF_CMD --type f"
export FZF_CTRL_T_COMMAND="$FZF_CMD"
export FZF_CTRL_T_OPTS='--preview "(highlight -O ansi -l {} || cat {} || tree -C {}) 2> /dev/null | head -200" --bind "?:toggle-preview"'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"
export FZF_ALT_C_COMMAND="$FZF_CMD --type d ."
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_VIM_LOG=$(git config --get alias.l | awk '{$1=""; print $0;}' | tr -d '\r')

export HOMEBREW_INSTALL_BADGE="⚽️"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_FORCE_BREWED_GIT=1
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
export PURE_GIT_BRANCH=" "

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

(( $+commands[jira] )) && eval "$(jira --completion-script-zsh)"

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
