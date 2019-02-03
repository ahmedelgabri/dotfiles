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
  if (( $+commands[curl] )); then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"
  else
    echo 'curl not found' >&2
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
# }}}

# Local plugins/completions/etc... {{{
  zplugin ice lucid atinit'local i; for i in *.zsh; do source $i; done'
  zplugin light %HOME/.zsh.d/functions

  zplugin light %HOME/.zsh.d/aliases
# }}}

##############################################################
# PLUGINS VARS & SETTINGS
##############################################################

############### Autosuggest
ZSH_AUTOSUGGEST_USE_ASYNC=true

############### History Substring
# bind UP and DOWN keys
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# bind UP and DOWN arrow keys (compatibility fallback)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

############### pure.zsh
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
# Old icon 
export PURE_GIT_BRANCH="  "

############### Python
export PYTHONSTARTUP="${HOME}/.pyrc.py"

############### z.sh
[[ -f "${HOMEBREW_ROOT}/etc/profile.d/z.sh" ]] && source "${HOMEBREW_ROOT}/etc/profile.d/z.sh"

############### grc
[[ -f "${HOMEBREW_ROOT}/etc/grc.zsh" ]] && source "${HOMEBREW_ROOT}/etc/grc.zsh"

############### FZF
if [[ -f "${XDG_CONFIG_HOME}/fzf/fzf.zsh" ]]; then
  source "${XDG_CONFIG_HOME}/fzf/fzf.zsh"
else
  echo "y" | "${HOMEBREW_ROOT}/opt/fzf/install" --xdg --no-update-rc
fi

export FZF_VIM_PATH="${HOMEBREW_ROOT}/opt/fzf" # used in vim
export FZF_VIM_LOG=$(git config --get alias.l | awk '{$1=""; print $0;}' | tr -d '\r')

if (( $+commands[fd] )); then
  export FZF_CMD='fd --hidden --follow --no-ignore-vcs --exclude ".git/*" --exclude "node_modules/*"'
  export FZF_DEFAULT_COMMAND="$FZF_CMD --type f"
  export FZF_CTRL_T_COMMAND="$FZF_CMD"
  export FZF_ALT_C_COMMAND="$FZF_CMD --type d ."
elif (( $+commands[rg] )); then
  export FZF_CMD='rg --no-messages --no-ignore-vcs'
  export FZF_DEFAULT_COMMAND="$FZF_CMD --files"
  export FZF_CTRL_T_COMMAND="$FZF_CMD"
fi

export FZF_DEFAULT_OPTS='--min-height 30 --height 50% --reverse --tabstop 2 --multi --margin 0,3,3,3'
export FZF_CTRL_T_OPTS='--preview-window right:60% --preview "(bat --style=numbers,changes --wrap never --color always {} || highlight -O ansi -l {} || cat {} || tree -C {}) 2> /dev/null | head -200" --bind "?:toggle-preview"'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

############### Homebrew
export HOMEBREW_INSTALL_BADGE="⚽️"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_FORCE_BREWED_GIT=1

############### Bat, Ripgrep, Weechat
export BAT_CONFIG_PATH="${HOME}/.batrc"
export RIPGREP_CONFIG_PATH="${HOME}/.rgrc"
export WEECHAT_PASSPHRASE=`security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`

############### Exa
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

############### Direnv
export N_PREFIX="${HOME}/.n"
export NODE_VERSIONS="${N_PREFIX}/n/versions/node"
export NODE_VERSION_PREFIX=""
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

############### Kitty
if [[ ! -z "${KITTY_WINDOW_ID}" ]]; then
  kitty + complete setup zsh | source /dev/stdin
fi

##############################################################
# /etc/motd
##############################################################

if [ -e /etc/motd ]; then
  if ! cmp -s ${HOME}/.hushlogin /etc/motd; then
    tee ${HOME}/.hushlogin < /etc/motd
  fi
fi

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
