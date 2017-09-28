" FZF
let g:fzf_files_options = $FZF_CTRL_T_OPTS
let g:fzf_layout = { 'window': 'enew' }
let g:fzf_commits_log_options = $FZF_VIM_LOG
let g:fzf_history_dir = '~/.fzf-history'

command! Plugs call fzf#run({
  \ 'source':  map(sort(keys(g:plugs)), 'g:plug_home."/".v:val'),
  \ 'options': '--delimiter / --nth -1',
  \ 'sink':    'Explore'})

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --hidden --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

nnoremap <silent> <leader><leader> :Files<cr>
nnoremap <silent> <Leader>c :Colors<cr>
nnoremap <silent> <Leader>b :Buffers<cr>
nnoremap <silent> <Leader>h :Helptags<cr>

function! s:fzf_statusline()
  " Override statusline as you like
  hi def link fzf1 airline_a
  hi def link fzf2 airline_b
  hi def link fzf3 airline_c
  setlocal statusline=%#fzf1#\ >\ %#fzf2#fzf\ %#fzf3#V:\ ctrl-v,\ H:\ ctrl-x
endfunction

autocmd! User FzfStatusLine call <SID>fzf_statusline()

