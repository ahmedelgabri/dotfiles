#
# Completion enhancements
#

#
# zsh options
#

setopt ALWAYS_TO_END # If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word
setopt PATH_DIRS     # Perform a path search even on command names with slashes in them.
unsetopt CASE_GLOB   # Make globbing (filename generation) not sensitive to case.
unsetopt LIST_BEEP   # Don't beep on an ambiguous completion.

#
# completion module options
#

# group matches and describe.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group yes
zstyle ':completion:*:options' description yes
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
# Context-aware verbose: disable for command name completion (fast), enable for subcommands/options (descriptive)
# This is critical for performance in direnv/nix-shell environments with large PATH
zstyle -e ':completion:*' verbose '[[ $context == command ]] && reply=(no) || reply=(yes)'
# Optimized matcher: case-insensitive + anchor matching at word boundaries
# Old '+r:|?=**' was too expensive (substring matching everywhere)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Complete flags/options
zstyle ':completion:*' complete-options true

# Only apply list-colors to file/directory completions, not commands
# Applying to all completions (default) is expensive with large lists
zstyle ':completion:*:*:*:*:files' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:directories' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'expand'
zstyle ':completion:*' squeeze-slashes true

# enable caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${ZDOTDIR}/.zcompcache"

# Performance optimizations
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-compctl false
# Limit max-errors for corrections to improve speed
zstyle ':completion:*:approximate:*' max-errors 1 numeric
# Show menu after 2 matches instead of listing all (faster for large lists)
zstyle ':completion:*' menu select=2
# ignore useless commands and functions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*)'

# completion sorting
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# history
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
