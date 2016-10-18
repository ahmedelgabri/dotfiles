" FZF
let g:fzf_files_options = $FZF_CTRL_T_OPTS
let g:fzf_layout = { 'window': 'enew' }
let g:fzf_commits_log_options = substitute(system("git config --get alias.lg | awk '{$1=\"\"; print $0;}'"), '\n\+$', '', '')
let g:fzf_history_dir = '~/.fzf-history'

command! Plugs call fzf#run({
  \ 'source':  map(sort(keys(g:plugs)), 'g:plug_home."/".v:val'),
  \ 'options': '--delimiter / --nth -1',
  \ 'sink':    'Explore'})

imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

nnoremap <silent> <leader><leader> :Files<cr>
nnoremap <silent> <Leader>c :Colors<cr>
nnoremap <silent> <Leader><Enter> :Buffers<cr>

function! s:fzf_statusline()
  " Override statusline as you like
  highlight fzf1 guifg=161 guibg=251
  highlight fzf2 guifg=23 guibg=251
  highlight fzf3 guifg=237 guibg=251
  setlocal statusline=%#fzf1#\ >\ %#fzf2#fzf\ %#fzf3#V:\ ctrl-v,\ H:\ ctrl-x
endfunction
autocmd! User FzfStatusLine call <SID>fzf_statusline()

