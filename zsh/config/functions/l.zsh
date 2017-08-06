unalias l 2> /dev/null

l(){
  if (( $+commands[exa] )); then
    if [[ "$1" == '--help' ]]; then
      exa --help
    else
      exa --all --long --group --header --links --color-scale --group-directories-first "$@"
    fi
  else
    # https://github.com/paulirish/dotfiles/blob/7c46f8c25015c2632894dbe5fea20014ab37fd89/.functions#L14-L25
    # List all files, long format, colorized, permissions in octal
    ls -AlhF --color=always "$@" | awk '
      {
        k=0;
        for (i=0;i<=8;i++)
          k+=((substr($1,i+2,1)~/[rwx]/) *2^(8-i));
        if (k)
          printf("%0o ",k);
        print;
      }'
  fi
}
