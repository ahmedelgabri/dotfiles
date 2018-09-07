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

let s:root=expand($DOTFILES.'/vim/.vim/')
let $VIMHOME= empty(glob(s:root)) ? expand('~/.vim/') : s:root

let &runtimepath .= ','.$VIMHOME.','.$VIMHOME.'/after'
execute 'set packpath^='.$VIMHOME

if !empty(glob($VIMHOME.'/autoload/bootstrap.vim'))
  call bootstrap#init()
endif
