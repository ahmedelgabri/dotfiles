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
   " jgs`-.__.\ _,--'\|__|__/
                    " ;____;
                     " \YT/
                      " ||
                     " |""|
                     " '=='

let s:root=expand('~/.dotfiles/vim/.vim')

if !empty(glob(s:root))
  let $VIMHOME=s:root
  let &runtimepath .= ','.$VIMHOME.','.$VIMHOME.'/after'
  call bootstrap#init()
endif
