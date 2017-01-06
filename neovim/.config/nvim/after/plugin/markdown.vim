let g:vim_markdown_fenced_languages = ['css', 'erb=eruby', 'javascript', 'js=javascript', 'json=json', 'ruby', 'sass', 'scss=sass', 'xml', 'html', 'python', 'stylus=css', 'less=css']
let g:vim_markdown_conceal = 0
let g:vim_markdown_frontmatter=1

let g:goyo_height = '95%'
let g:goyo_width = '120'
autocmd! User GoyoEnter GitGutterEnable
autocmd BufNewFile,BufReadPost *.md :Goyo
autocmd FileType mkd set | set autoindent | set colorcolumn=0 | set linebreak | set nonumber | set shiftwidth=4 | set spell | set tabstop=4 | set wrap
map <Leader>g :Goyo<CR>

function! s:goyo_enter()
  silent !tmux resize-pane -t $TMUX_PANE -Z

  let b:quitting = 0
  let b:quitting_bang = 0
  autocmd QuitPre <buffer> let b:quitting = 1
  cabbrev <buffer> q! let b:quitting_bang = 1 <bar> q!

  set noshowmode
  set noshowcmd
  set scrolloff=999
  Limelight
endfunction

function! s:goyo_leave()
  silent !tmux resize-pane -t $TMUX_PANE -Z

  " Quit Vim if this is the only remaining buffer
  if b:quitting && len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) == 1
    if b:quitting_bang
      qa!
    else
      qa
    endif
  endif

  set showmode
  set showcmd
  set scrolloff=5
  Limelight!
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

