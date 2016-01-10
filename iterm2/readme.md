to enable italics in iterm2 base on [https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/](https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/)

```sh
$ tic xterm-256color-italic.terminfo
```

Then add `xterm-256color-italic` in iterm2 config.

to test

```sh
$ echo `tput sitm`italics`tput ritm`
```


