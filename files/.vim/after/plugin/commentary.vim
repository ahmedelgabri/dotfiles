augroup MyCommentary
  autocmd!
  autocmd FileType ruby,python setl commentstring=#\ %s
  autocmd FileType htmldjango,jinja2 setl commentstring={#\ %s\ #}
augroup END
