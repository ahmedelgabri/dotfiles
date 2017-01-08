" leader is <space>
let mapleader = ' '
nnoremap <space> <nop>

" stolen from https://bitbucket.org/sjl/dotfiles/src/tip/vim/vimrc
" Keep search matches in the middle of the window.
nnoremap n nzzzv
nnoremap N Nzzzv

" Movement
"-----------------
" highlight last inserted text
nnoremap gV `[v`]

" Treat overflowing lines as having line breaks.
map j gj
map k gk

map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" Disable arrow keys (hardcore)
map  <up>    <nop>
imap <up>    <nop>
map  <down>  <nop>
imap <down>  <nop>
map  <left>  <nop>
imap <left>  <nop>
map  <right> <nop>
imap <right> <nop>

" Make arrowkey do something usefull, resize the viewports accordingly
nnoremap <Left> :vertical resize -2<CR>
nnoremap <Right> :vertical resize +2<CR>
nnoremap <Up> :resize -2<CR>
nnoremap <Down> :resize +2<CR>

nnoremap <silent> <leader>ev :e $MYVIMRC<CR>

nnoremap gv  :GV<CR> " tig like git explorer
vnoremap gv  :GV<CR> " tig like git explorer
nnoremap gb  :Gita browse --scheme=exact<CR> " Open current file on github.com
vnoremap gb  :Gita browse --scheme=exact<CR> " Make it work in Visual mode to open with highlighted linenumbers
nnoremap gs  :Gita status<CR>
vnoremap gs  :Gita status<CR>

" Quickly move current line, also accepts counts 2<leader>j
nnoremap <leader>k  :<c-u>execute 'move -1-'. v:count1<cr>
nnoremap <leader>j :<c-u>execute 'move +'. v:count1<cr>

nnoremap <leader>q :quit<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>x :xit<CR>

nnoremap <leader>tc :TernDocBrowse<CR>
nnoremap <leader>tr :TernRename<CR>
nnoremap <leader>td :TernDefSplit<CR>
nnoremap <leader>tf :TernRefs<CR>

" https://github.com/mhinz/vim-galore#quickly-edit-your-macros
nnoremap <leader>m  :<c-u><c-r>='let @'. v:register .' = '. string(getreg(v:register))<cr><c-f><left>

inoremap jj <ESC>
nnoremap \ :Grepper -side -tool rg -query<SPACE>
nnoremap \\ :Grepper -side -tool git -query<SPACE>
" nnoremap <silent> <leader>d :20Lex<CR>
nnoremap <silent> <leader>d :NERDTreeFind<CR>
nnoremap <Leader>bd :Sayonara!<CR>
nnoremap <Leader><TAB> <C-w><C-w>
nnoremap <leader>l <C-^>
" set text wrapping toggles
nnoremap <silent> <leader>tw :set invwrap<CR>:set wrap?<CR>
nnoremap -- :UndotreeToggle<CR>
nnoremap <leader>= <C-w>t<C-w>K<CR>
nnoremap <leader>\ <C-w>t<C-w>H<CR>
" Use | and _ to split windows (while preserving original behaviour of [count]bar and [count]_).
nnoremap <expr><silent> <Bar> v:count == 0 ? "<C-W>v<C-W><Right>" : ":<C-U>normal! 0".v:count."<Bar><CR>"
nnoremap <expr><silent> _     v:count == 0 ? "<C-W>s<C-W><Down>"  : ":<C-U>normal! ".v:count."_<CR>"

" open prev file
nnoremap <Leader>p :e#<CR>

" https://github.com/mhinz/vim-galore#dont-lose-selection-when-shifting-sidewards
xnoremap <  <gv
xnoremap >  >gv

" Save read only files
cmap w!! w !sudo tee % >/dev/null

" new file in current directory
nnoremap <Leader>n :e <C-R>=expand("%:p:h") . "/" <CR>


" Tab and Shift + Tab Circular buffer navigation
nnoremap <tab>   :bnext<CR>
nnoremap <S-tab> :bprevious<CR>


" use tab to toggle folds
" nnoremap <Enter> za


" qq to record, Q to replay
nnoremap Q @q

" Make dot work in visual mode
vmap . :norm.<CR>

" Enable very magic. :h magic
" nnoremap / /\v
" vnoremap / /\v
" cnoremap %s/ %s/\v
" cnoremap s/ s/\v

" For neovim terminal :term
if has('nvim')
  " nnoremap <leader>t  :vsplit +terminal<cr>
  " ignore when inisde FZF buffer
  tnoremap <expr> <esc> &filetype == 'fzf' ? "\<esc>" : "\<c-\>\<c-n>"
  tnoremap <a-h>      <c-\><c-n><c-w>h
  tnoremap <a-j>      <c-\><c-n><c-w>j
  tnoremap <a-k>      <c-\><c-n><c-w>k
  tnoremap <a-l>      <c-\><c-n><c-w>l
  autocmd BufEnter term://* startinsert
endif

nnoremap <silent> <leader>z :call functions#ZoomToggle<CR>
nmap <c-g> :call functions#SynStack()<CR>

vnoremap * :<c-u>call functions#VSetSearch()<cr>//<cr><c-o>
vnoremap # :<c-u>call functions#VSetSearch()<cr>??<cr><c-o>

map <leader>r :call functions#RenameFile()<cr>

nnoremap _$ :call functions#Preserve("%s/\\s\\+$//e")<CR>
nnoremap _= :call functions#Preserve("normal gg=G")<CR>

map <silent> <Leader>he :call functions#HtmlEscape()<CR>
map <silent> <Leader>hu :call functions#HtmlUnEscape()<CR>

" maintain the same shortcut as vim-gtfo becasue it's in my muscle memory.
nmap <silent> gof :call functions#OpenFileFolder()<CR>

