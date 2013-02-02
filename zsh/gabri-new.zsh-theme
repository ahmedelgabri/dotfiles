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

function rvm_info(){
    if [[ -s ~/.rvm/scripts/rvm ]] ; then
      echo "$FG[210][rvm:`~/.rvm/bin/rvm-prompt v`]%{$reset_color%} $EPS1"
    else
      if which rbenv &> /dev/null; then
        echo "$FG[117][`rbenv version | sed -e "s/ (set.*$//"`]%{$reset_color%} $EPS1"
      else
        echo "$EPS1"
      fi
    fi
}

##############################################################
# PROMPT Colors & config.
##############################################################

PROMPT='$FG[096]%~
$FG[003]⚡︎%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]$FG[242]"
ZSH_THEME_GIT_PROMPT_DIRTY="$FG[160]+"
ZSH_THEME_GIT_PROMPT_CLEAN="$FG[010]"

RPROMPT='$(git_prompt_info) $(rvm_info)'