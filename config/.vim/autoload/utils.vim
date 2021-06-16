scriptencoding utf-8
" [TODO]: Cleanup this file

function! utils#trim(txt) abort
  return substitute(a:txt, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

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


function! utils#setupWrapping() abort
  set wrap
  set wrapmargin=2
  set textwidth=80
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

fun! utils#ProfileStart(...)
  if a:0 && a:1 != 1
    let l:profile_file = a:1
  else
    let l:profile_file = '/tmp/vim.'.getpid().'.'.reltimestr(reltime())[-4:].'profile.txt'
    echom 'Profiling into' l:profile_file
    let @* = l:profile_file
  endif
  exec 'profile start '.l:profile_file
  profile! file **
  profile  func *
endfun

function! utils#NeatFoldText() abort
  let l:foldchar = matchstr(&fillchars, 'fold:\zs.')
  let l:lines=(v:foldend - v:foldstart + 1) . ' lines'
  let l:first=substitute(getline(v:foldstart), '\v *', '', '')
  let l:dashes=substitute(v:folddashes, '-', l:foldchar, 'g')
  return l:dashes . l:foldchar . l:foldchar . ' ' . l:lines . ': ' . l:first . ' '
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

function! utils#has_floating_window() abort
  " MenuPopupChanged was renamed to CompleteChanged -> https://github.com/neovim/neovim/pull/9819
  " https://github.com/neoclide/coc.nvim/wiki/F.A.Q#how-to-make-preview-window-shown-aside-with-pum
  return (exists('##MenuPopupChanged') || exists('##CompleteChanged')) && exists('*nvim_open_win') || (has('textprop') && has('patch-8.1.1522'))
endfunction

function! utils#create_floating_window() abort
  let s:buf = nvim_create_buf(v:false, v:true)

  let l:height = float2nr(&lines * 0.8)
  let l:width = float2nr(&columns * 0.9)
  let l:row = (&lines - l:height) / 2
  let l:col = (&columns - l:width) / 2
  let l:opts = {
        \ 'relative': 'editor',
        \ 'row': l:row,
        \ 'col': l:col,
        \ 'width': l:width,
        \ 'height': l:height,
        \ 'style': 'minimal'
        \ }

  let l:top = '╭' . repeat('─', l:width - 2) . '╮'
  let l:mid = '│' . repeat(' ', l:width - 2) . '│'
  let l:bot = '╰' . repeat('─', l:width - 2) . '╯'
  let l:lines = [l:top] + repeat([l:mid], l:height - 2) + [l:bot]

  call nvim_buf_set_lines(s:buf, 0, -1, v:true, l:lines)
  call nvim_open_win(s:buf, v:true, l:opts)

  set winhl=Normal:Floating

  let l:opts.row += 1
  let l:opts.height -= 2
  let l:opts.col += 2
  let l:opts.width -= 4

  call nvim_open_win(nvim_create_buf(v:false, v:true), v:true, l:opts)

  augroup FLOATING_WINDOW
    au!
    au BufWipeout <buffer> exe 'bw 's:buf
  augroup END
endfunction

function! utils#fzf_window() abort
  return utils#has_floating_window() ? { 'width': 0.9 , 'height': 0.8, 'relative': 1 } : 'enew'
endfunction

function! utils#toggle_term(cmd)
  if empty(bufname(a:cmd))
    call utils#create_floating_window()
    call termopen(a:cmd, { 'on_exit': function('OnTermExit') })
  else
    bwipeout!
  endif
endfunction

function! OnTermExit(job_id, code, event) dict
  if a:code == 0
    bwipeout!
  endif
endfunction

function! utils#toggle_tig()
  call utils#toggle_term('tig')
endfunction

function! utils#toggle_shell()
  call utils#toggle_term('zsh -l')
endfunction

function! utils#customize_diff()
  if &diff
    syntax off
    set number
  else
    syntax on
    set number&
  endif
endfunction

function! utils#get_color(synID, what, mode) abort
  return synIDattr(synIDtrans(hlID(a:synID)), a:what, a:mode)
endfunction

function! utils#is_git() abort
  silent call system('git rev-parse')
  return v:shell_error == 0
endfunction


function! utils#synnames(...) abort
  if a:0
    let [line, col] = [a:1, a:2]
  else
    let [line, col] = [line('.'), col('.')]
  endif
  return reverse(map(synstack(line, col), 'synIDattr(v:val,"name")'))
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
