#!/bin/sh

# Usage
# colortest

DOTS='•••'
printf "\n                 40m     41m     42m     43m     44m     45m     46m     47m\n";
for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
           '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
           '  36m' '1;36m' '  37m' '1;37m'; do
  FG=${FGs// /}
  printf " $FGs \033[$FG  $DOTS  "
  for BG in 40m 41m 42m 43m 44m 45m 46m 47m; do
    printf "$EINS \033[$FG\033[$BG  $DOTS  \033[0m";
  done
  printf "\n"
done
printf "\n"
unset -v DOTS
