## [My CTRL-H mapping doesn't work](https://github.com/neovim/neovim/wiki/FAQ#my-ctrl-h-mapping-doesnt-work)

Set kbs=\177 in your terminal's terminfo/termcap:

```
infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > $TERM.ti
tic $TERM.ti
```
