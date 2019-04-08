if !exists(':FZF')
  finish
endif

if !empty(expand($FZF_CTRL_T_OPTS))
  let g:fzf_files_options = $FZF_CTRL_T_OPTS
endif

if !empty(expand($VIM_FZF_LOG))
  let g:fzf_commits_log_options = $VIM_FZF_LOG
endif

let g:fzf_layout = { 'window': 'enew' }
let g:fzf_history_dir = expand('~/.fzf-history')
let g:fzf_buffers_jump = 1
let g:fzf_tags_command = 'ctags -R'

imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

nnoremap <silent> <leader><leader> :Files<cr>
nnoremap <silent> <Leader>b :Buffers<cr>
nnoremap <silent> <Leader>h :Helptags<cr>

function! s:fzf_statusline() abort
  setlocal statusline=%4*\ fzf\ %6*V:\ ctrl-v,\ H:\ ctrl-x,\ Tab:\ ctrl-t
endfunction

augroup MyFZF
  autocmd!
  autocmd! User FzfStatusLine call <SID>fzf_statusline()
augroup END

function! FzfSpellSink(word)
  exe 'normal! "_ciw'.a:word
endfunction
function! FzfSpell()
  let suggestions = spellsuggest(expand('<cword>'))
  return fzf#run({'source': suggestions, 'sink': function('FzfSpellSink'), 'down': 10 })
endfunction
nnoremap z= :call FzfSpell()<CR>
