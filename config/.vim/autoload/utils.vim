scriptencoding utf-8
" [TODO]: Cleanup this file

function! utils#ZoomToggle() abort
  if exists('t:zoomed') && t:zoomed
    exec t:zoom_winrestcmd
    let t:zoomed = 0
  else
    let t:zoom_winrestcmd = winrestcmd()
    resize
    vertical resize
    let t:zoomed = 1
  endif
endfunction

" Show highlighting groups for current word
" https://twitter.com/kylegferg/status/697546733602136065
function! utils#SynStack() abort
  if !exists('*synstack')
    return
  endif
  echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endfunc

" strips trailing whitespace at the end of files.
function! utils#Preserve(command) abort
  " Preparation: save last search, and cursor position.
  let l:pos=winsaveview()
  let l:search=@/
  " Do the business:
  keeppatterns execute a:command
  " Trim trailing blank lines
  " keeppatterns %s#\($\n\s*\)\+\%$##
  " Clean up: restore previous search history, and cursor position
  let @/=l:search
  nohlsearch
  call winrestview(l:pos)
endfunction

function! utils#ClearRegisters() abort
  let l:regs='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-="*+'
  let l:i=0
  while (l:i<strlen(l:regs))
    exec 'let @'.l:regs[l:i].'=""'
    let l:i=l:i+1
  endwhile
endfunction

" via: http://vim.wikia.com/wiki/HTML_entities
function! utils#HtmlEscape() abort
  silent s/&/\&amp;/eg
  silent s/</\&lt;/eg
  silent s/>/\&gt;/eg
endfunction

function! utils#HtmlUnEscape() abort
  silent s/&lt;/</eg
  silent s/&gt;/>/eg
  silent s/&amp;/\&/eg
endfunction

function! utils#OpenFileFolder() abort
  silent call system(utils#open() . ' '.expand('%:p:h:~'))
endfunction

function! utils#should_strip_whitespace(filetypelist) abort
  return index(a:filetypelist, &filetype) == -1
endfunction

function! utils#open() abort
  " Linux/BSD
  if executable('xdg-open')
    return 'xdg-open'
  endif
  " MacOS
  if executable('open')
    return 'open'
  endif
  " Windows
  return 'explorer'
endfunction

" Form: https://www.reddit.com/r/vim/comments/8asgjj/topnotch_vim_markdown_live_previews_with_no/
" Depends on `brew install grip`
function! utils#openMarkdownPreview() abort
  if exists('s:markdown_job_id') && s:markdown_job_id > 0
    call jobstop(s:markdown_job_id)
    unlet s:markdown_job_id
  endif
  let s:markdown_job_id = jobstart(
        \ 'grip --pass $GITHUB_TOKEN ' . shellescape(expand('%:p')) . " 0 2>&1 | awk '/Running/ { printf $4 }'",
        \ { 'on_stdout': 'OnGripStart', 'pty': 1 })
  function! OnGripStart(_, output, __)
    call system('open ' . a:output[0])
  endfunction
endfunction

function! utils#is_git() abort
  silent call system('git rev-parse')
  return v:shell_error == 0
endfunction

function! utils#helptopic() abort
  let col = col('.') - 1
  while col && getline('.')[col] =~# '\k'
    let col -= 1
  endwhile
  let pre = col == 0 ? '' : getline('.')[0 : col]
  let col = col('.') - 1
  while col && getline('.')[col] =~# '\k'
    let col += 1
  endwhile
  let post = getline('.')[col : -1]
  let syn = get(scriptease#synnames(), 0, '')
  let cword = expand('<cword>')
  if syn ==# 'vimFuncName'
    return cword.'()'
  elseif syn ==# 'vimOption'
    return "'".cword."'"
  elseif syn ==# 'vimUserAttrbKey'
    return ':command-'.cword
  elseif pre =~# '^\s*:\=$'
    return ':'.cword
  elseif pre =~# '\<v:$'
    return 'v:'.cword
  elseif cword ==# 'v' && post =~# ':\w\+'
    return 'v'.matchstr(post, ':\w\+')
  else
    return cword
  endif
endfunction
