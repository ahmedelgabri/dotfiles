let g:netrw_liststyle = 3
let g:netrw_banner = 0
" Next lines are taken from here https://github.com/h3xx/dotfiles/blob/master/vim/.vimrc#L543-L582
" horizontally split the window when opening a file via <cr>
let g:netrw_browse_split = 4
let g:netrw_sizestyle = 'H'
" split files below, right
let g:netrw_alto = 1
let g:netrw_altv = 1
let g:netrw_hide = 1

" bug workaround:
" set bufhidden=wipe in netrw windows to circumvent a bug where vim won't let
" you quit (!!!) if a netrw buffer doesn't like it
" also buftype should prevent you from :w
" (reproduce bug by opening netrw, :e ., :q)
let g:netrw_bufsettings = 'noma nomod nonu nobl nowrap ro' " default
let g:netrw_bufsettings .= ' buftype=nofile bufhidden=wipe'

let g:mapleader="\<Space>"
nnoremap <silent> <leader>d :20Lex<CR>
