if !exists(':Fern')
  finish
endif

let g:fern#disable_default_mappings=1
let g:fern#renderer#default#root_symbol="┬"
let g:fern#renderer#default#leaf_symbol=" "
let g:fern#renderer#default#collapsed_symbol="├ "
let g:fern#renderer#default#expanded_symbol="╰ "
let g:fern#default_hidden=1


function! s:init_fern() abort
  nmap <buffer><expr> <Plug>(fern-my-open-expand-collapse)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-action-open)",
        \   "\<Plug>(fern-action-expand)",
        \   "\<Plug>(fern-action-collapse)",
        \ )
  nmap <buffer> <CR> <Plug>(fern-my-open-expand-collapse)

  nmap <buffer> N <Plug>(fern-action-new-file)
  nmap <buffer> D <Plug>(fern-action-remove)
  nmap <buffer> H <Plug>(fern-action-hidden-toggle)j
  nmap <buffer> R <Plug>(fern-action-reload)
  nmap <buffer> m <Plug>(fern-action-mark-toggle)j
  nmap <buffer> s <Plug>(fern-action-open:split)
  nmap <buffer> v <Plug>(fern-action-open:vsplit)
  nmap <buffer> z <Plug>(fern-action-zoom)

  nmap <buffer> q :q<CR>
endfunction

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END

nnoremap <silent> - :Fern . -drawer -reveal=%<CR>
