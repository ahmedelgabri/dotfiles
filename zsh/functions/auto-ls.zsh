# Automatically list directory contents on `cd`.
auto-ls () {
  emulate -L zsh;
  # explicit sexy ls'ing as aliases arent honored in here.
  hash gls >/dev/null 2>&1 && CLICOLOR_FORCE=1 gls -AlhF --color --group-directories-first || ls
}
chpwd_functions=( auto-ls $chpwd_functions )
