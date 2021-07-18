if !exists(':FZF')
  finish
endif

if !empty(expand($FZF_CTRL_T_OPTS))
  let g:fzf_files_options = $FZF_CTRL_T_OPTS
endif

if !empty(expand($VIM_FZF_LOG))
  let g:fzf_commits_log_options = $VIM_FZF_LOG
endif

let g:fzf_layout = { 'window': { 'width': 0.9 , 'height': 0.8, 'relative': 1 } }
let g:fzf_history_dir = expand('~/.fzf-history')
let g:fzf_buffers_jump = 1
let g:fzf_tags_command = 'ctags -R'
let g:fzf_preview_window = 'right:border-left'

imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

" nnoremap <silent> <leader><leader> :Files<CR>
" nnoremap <silent> <Leader>b :Buffers<cr>
" nnoremap <silent> <Leader>h :Helptags<cr>

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

" nnoremap z= :call FzfSpell()<CR>

" https://github.com/junegunn/fzf.vim/issues/907#issuecomment-554699400
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always -g "!*.lock" -g "!*lock.json" --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
nnoremap <leader>\ :RG<CR>
