if !get(g:, 'mywaikikisetup_loaded', 0)
  call mywaikiki#Load()
  let g:mywaikikisetup_loaded = 1
endif

let g:vim_markdown_fenced_languages = [
      \'css',
      \'erb=eruby',
      \'javascript',
      \'js=javascript',
      \'jsx=javascript.jsx',
      \'ts=typescript',
      \'tsx=typescript.tsx',
      \'json',
      \'json5',
      \'ruby',
      \'sass',
      \'scss=sass',
      \'xml',
      \'html',
      \'py=python',
      \'python',
      \'clojure',
      \'clj=clojure',
      \'clojurescript',
      \'cljs=clojurescript',
      \'stylus=css',
      \'less=css'
      \]

let g:goyo_width = '120'
let g:limelight_conceal_ctermfg=240
let g:limelight_conceal_guifg = '#777777'
nmap <Leader>g :packadd goyo.vim<CR>\|:Goyo<CR>

" https://github.com/junegunn/goyo.vim/wiki/Customization
function! s:goyo_enter() abort
  packadd limelight.vim
  packadd goyo.vim
  Limelight
  if exists('$TMUX')
    silent !tmux set -g status off
    silent !tmux set -g pane-border-status off
    silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
  endif
  let b:quitting = 0
  let b:quitting_bang = 0
  augroup MyGoyoEnter
    autocmd!
    autocmd QuitPre <buffer> let b:quitting = 1
  augroup END
  cabbrev <buffer> q! let b:quitting_bang = 1 \| q!
endfunction

function! s:goyo_leave() abort
  Limelight!
  if exists('$TMUX')
    silent !tmux set -g status on
    silent !tmux set -g pane-border-status top
    silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
  endif
  " Quit Vim if this is the only remaining buffer
  if b:quitting && len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) == 1
    if b:quitting_bang
      silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
      qa!
    else
      silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
      qa
    endif
  endif
endfunction

augroup MyMarkdownGoyo
  autocmd!
  autocmd User GoyoEnter call <SID>goyo_enter()
  autocmd User GoyoLeave call <SID>goyo_leave()
augroup END
