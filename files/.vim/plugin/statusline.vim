scriptencoding utf-8

"------------------------------------------------------------------------------
" STATUS LINE CUSTOMIZATION
"------------------------------------------------------------------------------

function! StatusLine(mode) abort
  let l:line=''

  " help or man pages
  if &filetype ==# 'help' || &filetype ==# 'man'
    let l:line.=' %#StatusLineNC# ['. &filetype .'] %f '
    return l:line
  endif

  " active
  if a:mode ==# 'active'
    let l:line.='%6*%{statusline#gitInfo()}'
    let l:line.='%<'
    let l:line.=statusline#filepath()
    let l:line.='%4* %{statusline#fileSize()}%*'

    let l:line.='%5*'
    let l:line.=' %{statusline#readOnly()} %w%*'
    let l:line.='%9* %=%*'

    let l:line.='%{statusline#getMode()} %*'
    if &paste
      let l:line.='%#ErrorMsg#%{" '. functions#GetIcon('paste') .' "}%*'
    endif
    if &spell
      let l:line.='%#WarningMsg#%{" '. functions#GetIcon('spell') .' "}%*'
    endif
    let l:line.=statusline#LinterStatus()
    if exists('*statusline#statusDiagnostic')
      let l:line.='%4* %*'
      let l:line.=statusline#statusDiagnostic()
    endif
    let l:line.='%4* '. &filetype " %y will have [] around the test & %Y is uppercase so &filetype gives me what I want
    if &fileformat !=# 'unix'
      let l:line.='%4* %{&ff}%*'
    endif
    if &fileencoding !=# 'utf-8'
      let l:line.='%4* %{&fenc}%*'
    endif
    let l:line.='%4* %{statusline#rhs()}%* '
  else
    " inactive
    let l:line.='%#StatusLineNC#'
    let l:line.='%f'
  endif

  let l:line.='%*'

  return l:line
endfunction

set statusline=%!StatusLine('active')
augroup MyStatusLine
  autocmd!
  autocmd WinEnter * setl statusline=%!StatusLine('active')
  autocmd WinLeave * setl statusline=%!StatusLine('inactive')
  if exists('#TextChangedI')
    autocmd TextChanged,TextChangedI * call statusline#getMode()
  endif
  autocmd BufWinEnter,BufWritePost,FileWritePost,WinEnter,InsertEnter,InsertLeave,CmdWinEnter,CmdWinLeave,ColorScheme * call statusline#getMode()
augroup END
