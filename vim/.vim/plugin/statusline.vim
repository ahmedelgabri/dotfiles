scriptencoding utf-8

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------
function! StatusLine(mode) abort
  let l:line=''

  if &filetype ==# 'help'
    return '%#StatusLineNC# [Help] %f'
  endif

  if a:mode ==# 'active'
    let l:line.=' %{statusline#getMode()} %*'
    if &paste
      let l:line.='%#ErrorMsg#%{" ⍴ "}%*'
    endif
    if &spell
      let l:line='%#WarningMsg#%{" ✎  "}%*'
    endif
    let l:line.='%6*%{statusline#gitInfo()}'
    let l:line.=statusline#GetHunks()
    let l:line.='%<'
    let l:line.='%4* %{statusline#fileprefix()}%*'
    let l:line.='%6*%t'
    let l:line.=statusline#modified()

    let l:line.='%5*'
    let l:line.=' %{statusline#readOnly()} %w%*'
    let l:line.='%9* %=%*'

    if get(b:, 'show_highlight')
      let l:id = synID(line('.'), col('.'), 1)
      let l:line .='%#WarningMsg#['
            \ . '%{synIDattr('.l:id.',"name")} as '
            \ . '%{synIDattr(synIDtrans('.l:id.'),"name")}'
            \ . '] %*'
    endif

    let l:line.=statusline#LinterStatus()
    let l:line.='%4* %y'
    if &fileformat !=# 'unix'
      let l:line.='%4* %{&ff}%*'
    endif
    if &fileencoding !=# 'utf-8'
      let l:line.='%4* %{&fenc}%*'
    endif
    let l:line.='%4* %{statusline#rhs()}%*'
  else
    let l:line.='%#StatusLineNC#'
    let l:line.='%f'
  endif

  let l:line.='%*'

  return l:line
endfunction

" execute 'highlight! link User1 Function'
" execute 'highlight! link User2 NonText'
" execute 'highlight! link User3 Todo'
execute printf('highlight! User4 gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('NonText'),'fg', 'gui'), synIDattr(hlID('NonText'),'fg', 'cterm'))
execute 'highlight! User5 ctermfg=red guifg=red'
execute 'highlight! User7 ctermfg=cyan guifg=cyan'
" execute 'highlight! link User8 PmenuSel'
" execute 'highlight! link User9 PmenuSel'
execute printf('highlight! StatusLineNC gui=italic cterm=italic guibg=NONE ctermbg=NONE guifg=%s ctermfg=%s', synIDattr(hlID('NonText'),'fg', 'gui'), synIDattr(hlID('NonText'),'fg', 'cterm'))

set statusline=%!StatusLine('active')
augroup MyStatusLine
  autocmd!
  autocmd WinEnter * setl statusline=%!StatusLine('active')
  autocmd WinLeave * setl statusline=%!StatusLine('inactive')
  if exists('#TextChangedI')
    autocmd BufWinEnter,BufWritePost,FileWritePost,TextChanged,TextChangedI,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
  else
    autocmd BufWinEnter,BufWritePost,FileWritePost,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
  endif
augroup END
