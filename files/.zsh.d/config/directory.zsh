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
