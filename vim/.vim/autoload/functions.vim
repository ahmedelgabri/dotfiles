scriptencoding utf-8

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
  if !exists('*synstack')
    return
  endif
  echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endfunc

" https://github.com/garybernhardt/dotfiles/blob/68554d69652cc62d43e659f2c6b9082b9938c72e/.vimrc#L182-L194
function! functions#RenameFile()
  let l:old_name = expand('%')
  let l:new_name = input('New file name: ', expand('%'), 'file')
  if l:new_name !=# '' && l:new_name !=# l:old_name
    exec ':saveas ' . l:new_name
    exec ':silent !rm ' . l:old_name
    redraw!
  endif
endfunction


" strips trailing whitespace at the end of files.
function! functions#Preserve(command)
  " Preparation: save last search, and cursor position.
  let l:pos=winsaveview()
  let l:search=@/
  " Do the business:
  keepjumps execute a:command
  " Clean up: restore previous search history, and cursor position
  let @/=l:search
  nohlsearch
  call winrestview(l:pos)
endfunction


function! functions#ClearRegisters()
  let l:regs='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-="*+'
  let l:i=0
  while (l:i<strlen(l:regs))
    exec 'let @'.l:regs[l:i].'=""'
    let l:i=l:i+1
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
  let l:is_iTerm = exists('$TERM_PROGRAM') && $TERM_PROGRAM =~# 'iTerm.app'
  if l:is_iTerm
    if exists('g:colors_name')
      let l:profile = g:colors_name
      " if index(dual_colorschemes, g:colors_name) >= 0
      "   let profile .= '_'.&background
      "   echo profile
      " endif
      let l:escape = '\033]50;SetProfile='.l:profile.'\x7'
      if exists('$TMUX')
        let l:escape = '\033Ptmux;'.substitute(l:escape, '\\033', '\\033\\033', 'g').'\033\\'
      endif
      " for some reason it always sets BG to light?
      silent call system("printf '".l:escape."' > /dev/tty")
    endif
  endif
endfunction

" Loosely based on: http://vim.wikia.com/wiki/Make_views_automatic
" from https://github.com/wincent/wincent/blob/c87f3e1e127784bb011b0352c9e239f9fde9854f/roles/dotfiles/files/.vim/autoload/autocmds.vim#L20-L37
let g:GabriMkviewFiletypeBlacklist = ['diff', 'hgcommit', 'gitcommit']
function! functions#should_mkview() abort
  return
        \ &buftype ==# '' &&
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

function! functions#hasFileType(list) abort
  return index(a:list, &filetype) != -1
endfunction

let g:GabriQuitOnQ = ['preview', 'qf', 'fzf', 'netrw', 'help', 'taskedit']
function! functions#should_quit_on_q() abort
  return functions#hasFileType(g:GabriQuitOnQ)
endfunction

let g:GabriNoColorcolumn = ['qf', 'fzf', 'netrw', 'help', 'markdown', 'startify', 'GrepperSide', 'txt']
function! functions#should_turn_off_colorcolumn() abort
  return functions#hasFileType(g:GabriNoColorcolumn)
endfunction

let g:GabriKeepWhitespace = ['markdown']
function! functions#should_strip_whitespace() abort
  return index(g:GabriKeepWhitespace, &filetype) == -1
endfunction


fun! functions#ProfileStart(...)
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


function! functions#NeatFoldText()
  let l:raquo='»'
  let l:foldchar = matchstr(&fillchars, 'fold:\zs.')
  let l:lines=(v:foldend - v:foldstart + 1) . ' lines'
  let l:first=substitute(getline(v:foldstart), '\v *', '', '')
  let l:dashes=substitute(v:folddashes, '-', l:foldchar, 'g')
  return l:raquo . l:dashes . l:foldchar . l:foldchar . l:lines . ': ' . l:first
endfunction

function! functions#setupCompletion() abort
  " Some crazy magic to make nvim-completion-manager & UltiSnips work nicely together using `<Tab>`
  " It doesn't work when added to plugin/after/ultisnips.vim so for now it's here
  " https://github.com/roxma/nvim-completion-manager/issues/12#issuecomment-284196219
  let g:UltiSnipsExpandTrigger = '<Plug>(ultisnips_expand)'
  let g:UltiSnipsJumpForwardTrigger = '<Plug>(ultisnips_expand)'
  let g:UltiSnipsJumpBackwardTrigger = '<Plug>(ultisnips_backward)'
  let g:UltiSnipsListSnippets = '<Plug>(ultisnips_list)'
  let g:UltiSnipsRemoveSelectModeMappings = 0

  vnoremap <expr> <Plug>(ultisnip_expand_or_jump_result) g:ulti_expand_or_jump_res?'':"\<Tab>"
  inoremap <expr> <Plug>(ultisnip_expand_or_jump_result) g:ulti_expand_or_jump_res?'':"\<Tab>"
  imap <silent> <expr> <Tab> (pumvisible() ? "\<C-n>" : "\<C-r>=UltiSnips#ExpandSnippetOrJump()\<cr>\<Plug>(ultisnip_expand_or_jump_result)")
  xmap <Tab> <Plug>(ultisnips_expand)
  smap <Tab> <Plug>(ultisnips_expand)

  vnoremap <expr> <Plug>(ultisnips_backwards_result) g:ulti_jump_backwards_res?'':"\<S-Tab>"
  inoremap <expr> <Plug>(ultisnips_backwards_result) g:ulti_jump_backwards_res?'':"\<S-Tab>"
  imap <silent> <expr> <S-Tab> (pumvisible() ? "\<C-p>" : "\<C-r>=UltiSnips#JumpBackwards()\<cr>\<Plug>(ultisnips_backwards_result)")
  xmap <S-Tab> <Plug>(ultisnips_backward)
  smap <S-Tab> <Plug>(ultisnips_backward)

  " optional
  inoremap <silent> <c-u> <c-r>=cm#sources#ultisnips#trigger_or_popup("\<Plug>(ultisnips_expand)")<cr>
endfunction


" Project specific override
" Better than what I had before https://github.com/mhinz/vim-startify/issues/292#issuecomment-335006879
function! functions#sourceProjectConfig() abort
  let l:projectfile = findfile('.local.vim', expand('%:p').';')
  if filereadable(l:projectfile)
    silent execute 'source' l:projectfile
  endif
endfunction

