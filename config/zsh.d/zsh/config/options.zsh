##############################################################
# generic options and environment settings
###############################################################

# Use smart URL pasting and escaping.
autoload -Uz bracketed-paste-url-magic && zle -N bracketed-paste bracketed-paste-url-magic
autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic

setopt AUTO_RESUME          # Treat single word simple commands without redirection as candidates for resumption of an existing job.
setopt INTERACTIVE_COMMENTS # Allow comments starting with `#` even in interactive shells.
setopt NO_FLOW_CONTROL      # disable start (C-s) and stop (C-q) characters
setopt CORRECT              # Suggest command corrections
setopt LONG_LIST_JOBS       # List jobs in the long format by default.
setopt NOTIFY               # Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt NO_BG_NICE           # Prevent runing all background jobs at a lower priority.
setopt NO_CHECK_JOBS        # Prevent reporting the status of background and suspended jobs before exiting a shell with job control. NO_CHECK_JOBS is best used only in combination with NO_HUP, else such jobs will be killed automatically.
setopt NO_HUP               # Prevent sending the HUP signal to running jobs when the shell exits.
setopt NO_BEEP              # Don't beep on erros (overrides /etc/zshrc in Catalina)

##############################################################
#  History options
###############################################################

# limit of history entries
HISTORY_IGNORE='(clear|c|pwd|exit|* —help|[bf]g *|less *|cd ..|cd -)'

setopt BANG_HIST                 # Perform textual history expansion, csh-style, treating the character ‘!’ specially.
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks from each command line being added to the history list.
setopt APPEND_HISTORY            # append to history file
setopt HIST_NO_STORE             # Don't store history commands
setopt HIST_NO_FUNCTIONS         # Don't store function definitions
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks from each command line being added to the history list.


##############################################################
# Directory navigation options
###############################################################

setopt AUTO_CD           # If a command is issued that can’t be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory.
setopt AUTO_PUSHD        # Make cd push the old directory onto the directory stack.
setopt PUSHD_IGNORE_DUPS # Don’t push multiple copies of the same directory onto the directory stack.
setopt PUSHD_SILENT      # Do not print the directory stack after pushd or popd.
setopt PUSHD_TO_HOME     # Have pushd with no arguments act like ‘pushd ${HOME}’.
setopt AUTOPARAMSLASH    # tab completing directory appends a slash

#
# Globbing and fds
#

setopt EXTENDED_GLOB     # Treat the ‘#’, ‘~’ and ‘^’ characters as part of patterns for filename generation, etc. (An initial unquoted ‘~’ always produces named directory expansion.)
setopt MULTIOS           # Perform implicit tees or cats when multiple redirections are attempted.
setopt NO_CLOBBER        # Disallow ‘>’ redirection to overwrite existing files. ‘>|’ or ‘>!’ must be used to overwrite a file.
