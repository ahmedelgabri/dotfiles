# From https://github.com/sindresorhus/pure/blob/master/prompt.zsh#L14
# git:
# %b => current branch
# %a => current action (rebase/merge)
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)

##############################################################
# Setting the tab titles to the current directory
##############################################################

function precmd () {
  tab_label=${PWD/${HOME}/\~} # use 'relative' path
  echo -ne "\e]2;${tab_label}\a" # set window title to full string
  echo -ne "\e]1;${tab_label: -24}\a" # set tab title to rightmost 24 characters
}

##############################################################
# Showing Git branch name & status.
##############################################################

function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_PREFIX$(current_branch)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

##############################################################
# Show Ruby "RVM" version.
##############################################################

# function rvm_info(){
#     if [[ -s ~/.rvm/scripts/rvm ]] ; then
#       echo "%F{red}`~/.rvm/bin/rvm-prompt v`%{$reset_color%} $EPS1"
#     else
#       if which rbenv &> /dev/null; then
#         echo "%F{red}`rbenv version | sed -e "s/ (set.*$//"`%{$reset_color%} $EPS1"
#       else
#         echo "$EPS1"
#       fi
#     fi
# }

##############################################################
# PROMPT Colors & config.
##############################################################

PROMPT='
%F{074}%~ $(git_prompt_info)
%F{172}⚡︎%f '

ZSH_THEME_GIT_PROMPT_PREFIX="["
ZSH_THEME_GIT_PROMPT_SUFFIX="]"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{160}"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{070}"

RPROMPT='' # $(rvm_info)


