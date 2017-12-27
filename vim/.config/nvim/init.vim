let g:VIM_CONFIG_FOLDER=expand('~/.dotfiles/vim/.vim')
let &runtimepath .= ','.g:VIM_CONFIG_FOLDER.','.g:VIM_CONFIG_FOLDER.'/after'
execute 'source'.g:VIM_CONFIG_FOLDER.'/main.vim'
