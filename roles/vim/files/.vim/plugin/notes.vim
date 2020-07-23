" https://vimways.org/2019/personal-notetaking-in-vim/
" https://danishpraka.sh/2020/02/23/journaling-in-vim.html

let s:NOTES_DIR = expand('$NOTES_DIR')

command! -complete=customlist,GetNotesCompletion -nargs=? Note call <SID>note_edit(<f-args>)
command! -nargs=? Wiki call <SID>wiki_edit(<f-args>)
command! -bang Notes call fzf#vim#files(s:NOTES_DIR)

nnoremap <silent> <leader>sn :Notes<CR>

func! GetNotesCompletion(ArgLead, CmdLine, CursorPos) abort
  return map(getcompletion(s:NOTES_DIR . '/*/**/', 'dir'), {i,v -> substitute(v, '\m\C^'.$HOME.'/', '~/', '')})
endfunc

func! s:note_edit(...) abort

  " build the file name
  let l:sep = '-'
  let l:path = s:NOTES_DIR . '/'
  let l:fname = len(a:000) > 0 ? tolower(trim(a:000[0])) : ''

  if len(a:000) > 0 && stridx(a:000[0], "~/") == 0
    let l:path = fnamemodify(a:000[0], ':h') . '/'
    let l:fname = tolower(fnamemodify(a:000[0], ':t:r'))
  endif

  let l:path .= strftime('%Y/%m/%d/%H-%M-%S') . (l:fname !=# '' ? l:sep : '') . l:fname . '.md'

  echo l:path

  " edit the new file
  exec 'e ' . l:path

  " Add metadata (date, etc...) on the top of the file
  exec "normal ggO---\<cr>date: \<c-r>=strftime('%A %B %d, %Y %H:%M')\<cr>\<cr>title: " . l:fname . "\<cr>---\<cr>\<esc>G"

  silent! packadd goyo.vim
  silent! Goyo
endfunc


func! s:wiki_edit(...) abort

  " build the file name
  let l:sep = ''
  if len(a:000) > 0
    let l:sep = '-'
  endif
  let l:fname = s:NOTES_DIR . '/wiki/' . join(a:000, '-') . '.md'

  echo l:fname

  " edit the new file
  exec 'e ' . l:fname

  silent! packadd goyo.vim
  silent! Goyo
endfunc
