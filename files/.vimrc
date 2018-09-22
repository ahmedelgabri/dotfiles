                                " _ .--.
                                " ( `    )
                             " .-'      `--,
                  " _..----.. (             )`-.
                " .'_|` _|` _|(  .__,           )
               " /_|  _|  _|  _(        (_,  .-'
              " ;|  _|  _|  _|  '-'__,--'`--'
              " | _|  _|  _|  _| |
          " _   ||  _|  _|  _|  _|
        " _( `--.\_|  _|  _|  _|/
     " .-'       )--,|  _|  _|.`
    " (__, (_      ) )_|  _| /
      " `-.__.\ _,--'\|__|__/
                    " ;____;
                     " \YT/
                      " ||
                     " |""|
                     " '=='

let $VIMHOME= has('nvim') ? expand('~/.config/nvim') : expand('~/.vim')

let &runtimepath .= ','.$VIMHOME.','.$VIMHOME.'/after'
execute 'set packpath^='.$VIMHOME

if !exists('*bootstrap#init')
  call bootstrap#init()
endif
