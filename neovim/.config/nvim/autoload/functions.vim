function! functions#trim(txt)
  return substitute(a:txt, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

function! functions#ZoomToggle() abort
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
function! functions#SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc


" Visual Mode */# from Scrooloose
function! functions#VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp
endfunction

" https://github.com/garybernhardt/dotfiles/blob/68554d69652cc62d43e659f2c6b9082b9938c72e/.vimrc#L182-L194
function! functions#RenameFile()
  let old_name = expand('%')
  let new_name = input('New file name: ', expand('%'), 'file')
  if new_name != '' && new_name != old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
    redraw!
  endif
endfunction


" strips trailing whitespace at the end of files. this
" is called on buffer write in the autogroup above.
function! functions#Preserve(command)
  " Preparation: save last search, and cursor position.
  let l:pos=getcurpos()
  let l:search=@/
  " Do the business:
  keepjumps execute a:command
  " Clean up: restore previous search history, and cursor position
  let @/=l:search
  nohlsearch
  call setpos('.', l:pos)
endfunction


function! functions#ClearRegisters()
  let regs='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-="*+'
  let i=0
  while (i<strlen(regs))
    exec 'let @'.regs[i].'=""'
    let i=i+1
  endwhile
endfunction


function! functions#setupWrapping()
  set wrap
  set wrapmargin=2
  set textwidth=80
endfunction

" via: http://vim.wikia.com/wiki/HTML_entities
function! functions#HtmlEscape()
  silent s/&/\&amp;/eg
  silent s/</\&lt;/eg
  silent s/>/\&gt;/eg
endfunction

function! functions#HtmlUnEscape()
  silent s/&lt;/</eg
  silent s/&gt;/>/eg
  silent s/&amp;/\&/eg
endfunction

function! functions#OpenFileFolder()
  silent call system('open '.expand('%:p:h:~'))
endfunction

" https://github.com/vheon/home/blob/b4535fdfd0cb2df93284f69d676d587b3e2b2a21/.vim/vimrc#L318-L339
" When switching colorscheme in terminal vim change the profile in iTerm as well.
function! functions#change_iterm2_profile()
  " let dual_colorschemes = ['onedark', 'gruvbox']
  let is_iTerm = exists('$TERM_PROGRAM') && $TERM_PROGRAM =~# 'iTerm.app'
  if is_iTerm
    if exists('g:colors_name')
      let profile = g:colors_name
      " if index(dual_colorschemes, g:colors_name) >= 0
      "   let profile .= '_'.&background
      "   echo profile
      " endif
      let escape = '\033]50;SetProfile='.profile.'\x7'
      if exists('$TMUX')
        let escape = '\033Ptmux;'.substitute(escape, '\\033', '\\033\\033', 'g').'\033\\'
      endif
      " for some reason it always sets BG to light?
      silent call system("printf '".escape."' > /dev/tty")
    endif
  endif
endfunction

" Loosely based on: http://vim.wikia.com/wiki/Make_views_automatic
" from https://github.com/wincent/wincent/blob/c87f3e1e127784bb011b0352c9e239f9fde9854f/roles/dotfiles/files/.vim/autoload/autocmds.vim#L20-L37
let g:GabriMkviewFiletypeBlacklist = ['diff', 'hgcommit', 'gitcommit']
function! functions#should_mkview() abort
  return
        \ &buftype == '' &&
        \ index(g:GabriMkviewFiletypeBlacklist, &filetype) == -1 &&
        \ !exists('$SUDO_USER') " Don't create root-owned files.
endfunction

function! functions#mkview() abort
  if exists('*haslocaldir') && haslocaldir()
    " We never want to save an :lcd command, so hack around it...
    cd -
    mkview
    lcd -
  else
    mkview
  endif
endfunction

function! functions#ToggleTextLimit(limit)
  if &colorcolumn == l:limit
    let &colorcolumn='+' . join(range(0, 254), ',+')
  else
    let &colorcolumn = l:limit
  endif
endfunction

let g:GabriQuitOnQBlacklist = ['preview', 'ag', 'qf', 'gita-status', 'fzf', 'netrw', 'help']
function! functions#should_quit_on_q()
  return index(g:GabriQuitOnQBlacklist, &filetype) == -1
endfunction

let g:GabriNoColorcolumn = ['qf', 'fzf', 'netrw', 'help', 'markdown', 'startify']
function! functions#should_turn_off_colorcolumn()
  return index(g:GabriNoColorcolumn, &filetype) == -1
endfunction


