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

let s:root=expand($DOTFILES.'/vim/.vim')

if !empty(glob(s:root))
  let $VIMHOME=s:root
else
  let $VIMHOME=expand('~/.vim')
endif

let &runtimepath .= ','.$VIMHOME.','.$VIMHOME.'/after'
execute 'set packpath^='.$VIMHOME

if !empty(glob($VIMHOME.'/autoload/bootstrap.vim'))
  call bootstrap#init()
endif
