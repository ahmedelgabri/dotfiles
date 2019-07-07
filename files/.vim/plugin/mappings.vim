" Plugin mappings are inside plugin/after/<plugin name>.vim files

" stolen from https://bitbucket.org/sjl/dotfiles/src/tip/vim/vimrc
" The `zzzv` keeps search matches in the middle of the window.
" and make sure n will go forward when searching with ? or #
" https://vi.stackexchange.com/a/2366/4600
nnoremap <expr> n (v:searchforward ? 'n' : 'N') . 'zzzv'
nnoremap <expr> N (v:searchforward ? 'N' : 'n') . 'zzzv'

" Movement
"-----------------
" highlight last inserted text
nnoremap gV `[v`]

" Move by 'display lines' rather than 'logical lines' if no v:count was
" provided.  When a v:count is provided, move by logical lines.
nnoremap <expr> j v:count ? 'j' : 'gj'
xnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'
xnoremap <expr> k v:count ? 'k' : 'gk'

" Make `Y` behave like `C` and `D` (to the end of line)
nnoremap Y y$

" https://twitter.com/vimgifs/status/913390282242232320
" :h i_CTRL-G_u
augroup PROSE_MAPPINGS
  au!
  au FileType markdown,text inoremap <buffer> . .<c-g>u
  au FileType markdown,text inoremap <buffer> ? ?<c-g>u
  au FileType markdown,text inoremap <buffer> ! !<c-g>u
  au FileType markdown,text inoremap <buffer> , ,<c-g>u
augroup END

" Disable arrow keys
imap <up>    <nop>
imap <down>  <nop>
imap <left>  <nop>
imap <right> <nop>

" Make arrowkey do something usefull, resize the viewports accordingly
nnoremap <Right> :vertical resize -2<CR>
nnoremap <Left> :vertical resize +2<CR>
nnoremap <Down> :resize -2<CR>
nnoremap <Up> :resize +2<CR>

inoremap jj <ESC>
nnoremap <Leader><TAB> <C-w><C-w>
nnoremap <leader>= <C-w>t<C-w>K<CR>
nnoremap <leader>\ <C-w>t<C-w>H<CR>

" https://github.com/mhinz/vim-galore#dont-lose-selection-when-shifting-sidewards
xnoremap <  <gv
xnoremap >  >gv

" new file in current directory
nnoremap <Leader>n :e <C-R>=expand("%:p:h") . "/" <CR>

nnoremap <Leader>l :set nu! rnu!<cr>
nnoremap <Leader>p :t.<left><left>

" qq to record, Q to replay
nnoremap Q @q

" Make dot work in visual mode
vnoremap . :norm.<CR>

" For neovim terminal :term
if has('nvim')
  " nnoremap <leader>t  :vsplit +terminal<cr>
  tnoremap <expr> <esc> &filetype == 'fzf' ? "\<esc>" : "\<c-\>\<c-n>"
  tnoremap <M-h> <c-\><c-n><c-w>h
  tnoremap <M-j> <c-\><c-n><c-w>j
  tnoremap <M-k> <c-\><c-n><c-w>k
  tnoremap <M-l> <c-\><c-n><c-w>l
  augroup MyTerm
    autocmd!
    autocmd TermOpen * setl nonumber norelativenumber
    autocmd TermOpen term://* startinsert
    autocmd TermClose term://* stopinsert
  augroup END
endif

nnoremap <silent> <leader>z :call utils#ZoomToggle()<CR>
nnoremap <c-g> :call utils#SynStack()<CR>

if exists(':Move')
  nnoremap <leader>r :Move %<cr>
endif

nnoremap _$ :call utils#Preserve("%s/\\s\\+$//e")<CR>
nnoremap _= :call utils#Preserve("normal gg=G")<CR>

vmap <silent> <Leader>hu :call utils#HtmlUnEscape()<CR>
vmap <silent> <Leader>he :call utils#HtmlEscape()<CR>

" maintain the same shortcut as vim-gtfo becasue it's in my muscle memory.
nnoremap <silent> gof :call utils#OpenFileFolder()<CR>

" Allows you to visually select a section and then hit @ to run a macro on all lines
" https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db#.3dcn9prw6
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo '@'.getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction
