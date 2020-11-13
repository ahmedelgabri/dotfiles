if !exists('g:loaded_esearch')
  finish
endif

let g:esearch = {}

" Start the search only when the enter is hit instead of updating the pattern while you're typing.
let g:esearch.live_update = 1

let g:esearch.git_dir = {cwd -> FugitiveExtractGitDir(cwd)}
let g:esearch.git_url = {path, dir -> FugitiveFind(path, dir)}

" Show the popup with git-show information on CursorMoved is a git revision context is hovered.
let g:GitShow = {ctx -> ctx().rev &&
      \ esearch#preview#shell('git show ' . split(ctx().filename, ':')[0], {
      \   'let': {'&filetype': 'git', '&number': 0},
      \   'row': screenpos(0, ctx().begin, 1).row,
      \   'col': screenpos(0, ctx().begin, col([ctx().begin, '$'])).col,
      \   'width': 47, 'height': 3,
      \ })
      \}

nnoremap <leader>fh :call esearch#init({'paths': esearch#xargs#git_log()})<cr>
nmap \ <plug>(esearch)

if has('nvim')
  " Try to jump into the opened floating window or open a new one.
  let g:esearch.win_new = {esearch ->
        \ esearch#buf#goto_or_open(esearch.name, {name ->
        \   nvim_open_win(bufadd(name), v:true, {
        \     'relative': 'editor',
        \     'anchor': 'NE',
        \     'row': 0,
        \     'col': &columns,
        \     'width': &columns * 5 / 10,
        \     'height': &lines
        \   })
        \ })
        \}
endif

" Close the floating window when opening an entry.
augroup ESEARCH
  au!
  au User esearch_win_config autocmd BufLeave <buffer> quit
  " Debounce the popup updates using 70ms timeout.
  au User esearch_win_config
        \  let b:git_show = esearch#async#debounce(g:GitShow, 70)
        \| autocmd CursorMoved <buffer> call b:git_show.apply(b:esearch.ctx)
augroup END
