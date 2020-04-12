if !exists('g:loaded_eunuch')
  finish
endif

" This command & mapping shadows the ones in mappings.vim
" if the plugin is available then use the plugin, if not fallback to the other one.

" Move is more flexiabile thatn Rename
" https://www.youtube.com/watch?v=Av2pDIY7nRY
nmap <leader>m :Move <C-R>=expand("%")<cr>

" Delete the current file and clear the buffer
command! Del Delete
