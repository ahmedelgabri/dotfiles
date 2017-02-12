# A nice hack to use an `.ackrc` style file for ripgrep in `~/.config/rgrc`
# https://github.com/BurntSushi/ripgrep/issues/196#issuecomment-276375223

# function rg() {
#     declare -a OUTPUT

#     # -- Support an .ackrc-like .rgrc file --
#     # Blank lines and lines beginning with # are ignored
#     # All other lines are parsed together as if they ended with \
#     # and prepended onto $@ before calling rg.
#     CFG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/rgrc"
#     if [ -f "$CFG_PATH" ]; then
#         # Source: http://stackoverflow.com/a/10929511/435253
#         while read -r line || [[ -n "$line" ]]; do
#             if [ "$line" = "" ] || [[ "$line" == '#'* ]]; then
#                 continue
#             fi

#             # Source: http://stackoverflow.com/a/31485948/435253
#             while IFS= read -r -d ''; do
#                 OUTPUT+=( "$REPLY" )
#             done < <(xargs printf '%s\0' <<<"$line")
#         done < "$CFG_PATH"
#     fi

#     # -- Implement `-G ...` as an alternative to `-g !...` --
#     # Work around a footgun in zsh's handling of ! characters
#     for ARG in "$@"; do

#         if [[ "$ARG" = "-G"* ]]; then
#             OUTPUT+=( "-g" )
#             if [ "$ARG" = "-G" ]; then
#                 take_next=1
#             else
#                 OUTPUT+=( "!${ARG:2}" )
#             fi
#         elif [ "$take_next" = 1 ]; then
#             OUTPUT+=( "!$ARG" )
#             unset take_next
#         else
#             OUTPUT+=( "$ARG" )
#         fi
#     done

#     command rg "${OUTPUT[@]}"
# }
