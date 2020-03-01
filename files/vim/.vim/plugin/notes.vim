" https://vimways.org/2019/personal-notetaking-in-vim/
" https://danishpraka.sh/2020/02/23/journaling-in-vim.html

command! -nargs=* Note call <SID>note_edit(<f-args>)
command! -bang Notes call fzf#vim#files(expand('$NOTES_DIR'), <bang>0)

nnoremap <silent> <leader>ww :Notes<CR>

func! s:note_edit(...)

  " build the file name
  let l:sep = ''
  if len(a:000) > 0
    let l:sep = '-'
  endif
  let l:fname = expand('$NOTES_DIR') . '/' . strftime('%Y/%m/%d/%H:%M') . l:sep . join(a:000, '-') . '.md'

  " edit the new file
  exec 'e ' . l:fname

  " enter the title and timestamp (using ultisnips) in the new file
  if len(a:000) > 0
    exec "normal ggO\<c-r>=strftime('%Y-%m-%d %H:%M')\<cr> " . join(a:000) . "\<cr>\<esc>G"
  else
    exec "normal ggO\<c-r>=strftime('%Y-%m-%d %H:%M')\<cr>\<cr>\<esc>G"
  endif

  silent! packadd goyo.vim
  silent! Goyo
endfunc
