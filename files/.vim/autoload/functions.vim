scriptencoding utf-8
" @TODO: Cleanup this file

function! functions#trim(txt) abort
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
function! functions#SynStack() abort
  if !exists('*synstack')
    return
  endif
  echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endfunc

" strips trailing whitespace at the end of files.
function! functions#Preserve(command) abort
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


function! functions#ClearRegisters() abort
  let l:regs='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-="*+'
  let l:i=0
  while (l:i<strlen(l:regs))
    exec 'let @'.l:regs[l:i].'=""'
    let l:i=l:i+1
  endwhile
endfunction


function! functions#setupWrapping() abort
  set wrap
  set wrapmargin=2
  set textwidth=80
endfunction

" via: http://vim.wikia.com/wiki/HTML_entities
function! functions#HtmlEscape() abort
  silent s/&/\&amp;/eg
  silent s/</\&lt;/eg
  silent s/>/\&gt;/eg
endfunction

function! functions#HtmlUnEscape() abort
  silent s/&lt;/</eg
  silent s/&gt;/>/eg
  silent s/&amp;/\&/eg
endfunction

function! functions#OpenFileFolder() abort
  silent call system('open '.expand('%:p:h:~'))
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

let g:GabriQuitOnQ = ['preview', 'qf', 'fzf', 'netrw', 'help', 'taskedit']
function! functions#should_quit_on_q() abort
  return index(g:GabriQuitOnQ, &filetype) >= 0
endfunction

let g:GabriNoColorcolumn = [
      \'qf',
      \'fzf',
      \'netrw',
      \'help',
      \'markdown',
      \'startify',
      \'GrepperSide',
      \'text',
      \'gitconfig',
      \'gitrebase',
      \'conf',
      \'tags',
      \'vimfiler',
      \'dos',
      \'json'
      \'diff'
      \]
function! functions#should_turn_off_colorcolumn() abort
  return &textwidth == 0
        \|| index(g:GabriNoColorcolumn, &filetype) >= 0
        \|| &buftype ==# 'terminal' || &readonly
endfunction

function! functions#setOverLength()
  if functions#should_turn_off_colorcolumn()
    match NONE
  else
    " Stolen from https://github.com/whatyouhide/vim-lengthmatters/blob/74e248378544ac97fb139803b39583001c83d4ef/plugin/lengthmatters.vim#L17-L33
    let s:overlengthCmd = 'highlight OverLength'
    for l:md in ['cterm', 'term', 'gui']
      let l:bg = synIDattr(hlID('WildMenu'), 'bg', l:md)
      let l:fg = synIDattr(hlID('Normal'), 'fg', l:md)

      if has('gui_running') && l:md !=# 'gui'
        continue
      endif

      if !empty(l:bg) | let s:overlengthCmd .= ' ' . l:md . 'bg=' . l:bg | endif
      if !empty(l:fg) | let s:overlengthCmd .= ' ' . l:md . 'fg=' . l:fg | endif
    endfor
    exec s:overlengthCmd
    " Use tw + 1 so invisble characters are not marked
    let s:overlengthSize = &textwidth
    execute 'match OverLength /\%>'. s:overlengthSize .'v.*/'
  endif
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

function! functions#NeatFoldText() abort
  let l:foldchar = matchstr(&fillchars, 'fold:\zs.')
  let l:lines=(v:foldend - v:foldstart + 1) . ' lines'
  let l:first=substitute(getline(v:foldstart), '\v *', '', '')
  let l:dashes=substitute(v:folddashes, '-', l:foldchar, 'g')
  return l:dashes . l:foldchar . l:foldchar . ' ' . l:lines . ': ' . l:first . ' '
endfunction

function! s:show_documentation() abort
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

function! functions#setupCompletion() abort
  let g:UltiSnipsExpandTrigger      = "<c-u>"
  let g:UltiSnipsJumpForwardTrigger = "<c-j>"
  let g:UltiSnipsJumpBackwardTrigger    = "<c-k>"

  let g:coc_snippet_next = '<c-j>'
  let g:coc_snippet_prev = '<c-k>'

  inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<c-j>"
  inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<c-k>"
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
  inoremap <silent><expr> <c-space> coc#refresh()

  " imap <silent> <C-x><C-o> <Plug>(coc-complete-custom)
  imap <silent> <C-x><C-u> <Plug>(coc-complete-custom)
  " Use `[c` and `]c` for navigate diagnostics
  nmap <silent> [c <Plug>(coc-diagnostic-prev)
  nmap <silent> ]c <Plug>(coc-diagnostic-next)

  " Remap keys for gotos
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)

  " Use K for show documentation in preview window
  nnoremap <silent> K :call <SID>show_documentation()<CR>

  " Show signature help while editing
  autocmd! CursorHoldI,CursorMovedI * silent! call CocAction('showSignatureHelp')
endfunction


" Project specific override
" Better than what I had before https://github.com/mhinz/vim-startify/issues/292#issuecomment-335006879
function! functions#sourceProjectConfig() abort
  let l:projectfile = findfile('.local.vim', expand('%:p').';')
  if filereadable(l:projectfile)
    silent execute 'source' l:projectfile
  endif
endfunction

" https://github.com/wincent/wincent/commit/fe798113ffb7c616cb7c332c91eaffd62e781048
function! s:Visual()
  return visualmode() == 'V'
endfunction

function! s:Move(address, at_limit)
  if s:Visual() && !a:at_limit
    execute "'<,'>move " . a:address
    call feedkeys('gv=', 'n')
  endif
  call feedkeys('gv', 'n')
endfunction

function! functions#move_up() abort range
  let l:at_top=a:firstline == 1
  call s:Move("'<-2", l:at_top)
endfunction

function! functions#move_down() abort range
  let l:at_bottom=a:lastline == line('$')
  call s:Move("'>+1", l:at_bottom)
endfunction

function! functions#GetIcon(key) abort
  let l:ICONS = {
        \'paste': '⍴',
        \'spell': '✎',
        \'branch': '  ',
        \'linter_error': '×',
        \'linter_style': '●',
        \'lock': ' ',
        \}

  return get(l:ICONS, a:key, a:key)
endfunction
