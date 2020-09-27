let s:NOTES_DIR = expand('$NOTES_DIR')



func! notes#getDir() abort
  return s:NOTES_DIR
endfunc



func! notes#noteInfo(...) abort
  " build the file name
  let l:sep = '_'
  let l:path = s:NOTES_DIR . '/'
  let l:fname = len(a:000) > 0 ? tolower(trim(a:1)) : ''

  if len(a:000) > 0 && stridx(a:1, "~/") == 0
    let l:path = fnamemodify(a:1, ':h') . '/'
    let l:fname = tolower(fnamemodify(a:1, ':t:r'))
  endif

  let l:has_fname = l:fname !=# ''

  let l:path .= strftime('%Y-%m-%dT%H-%M-%S') . (l:has_fname ? l:sep : '') . l:fname . '.md'
  let l:tail = fnamemodify(l:path, ':t:r')

  return [l:path, l:has_fname ? split(l:tail, l:sep)[1] : '']
endfunc



func! notes#note_edit(...) abort
  let [l:path, l:fname] = call('notes#noteInfo', a:000)

  " edit the new file
  exec 'e ' . l:path

  " Add metadata (date, etc...) on the top of the file
  exec "normal ggO---\<cr>date: \<c-r>=strftime('%A, %B %d, %Y, %H:%M')\<cr>\<cr>title: " . l:fname . "\<cr>---\<cr>\<esc>G"

  silent! packadd goyo.vim
  silent! Goyo
endfunc



func! notes#wiki_edit(...) abort
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



func! notes#getNotesCompletion(ArgLead, CmdLine, CursorPos) abort
  return map(getcompletion(s:NOTES_DIR . '/*/**/', 'dir'), {i,v -> substitute(v, '\m\C^'.$HOME.'/', '~/', '')})
endfunc



func! notes#myName(...) abort
  let [_,l:fname] = call('notes#noteInfo', a:000)

  return l:fname
endfunc
