let s:root=expand('~/.dotfiles/vim/.vim')

if !empty(glob(s:root))
  let $VIMHOME=s:root
  let &runtimepath .= ','.$VIMHOME.','.$VIMHOME.'/after'
  execute 'source '.$VIMHOME.'/main.vim'
endif
