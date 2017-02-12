" deoplete currenty only works with neovim only
if has('nvim')
  " To benefit from deoplete lazy loading I don't call deoplete#enable() here
  " instead I set let g:deoplete#enable_at_startup = 1 in `.vimrc` directly

  let g:deoplete#enable_smart_case = 1
  let g:deoplete#enable_camel_case = 1
  let g:deoplete#auto_completion_start_length = 2
  let g:deoplete#file#enable_buffer_path = 1

  " Sort results alphabetically
  call deoplete#custom#set('_', 'sorters', ['sorter_word'])

  " chnage the ranking of utlisnips
  call deoplete#custom#set('ultisnips', 'rank', 1000)

  let g:deoplete#sources_           = ['buffer']
  let g:deoplete#sources_md         = ['buffer', 'dictionary', 'file', 'member']
  let g:deoplete#sources_vim        = ['buffer', 'member', 'file', 'ultisnips']
  let g:deoplete#sources_txt        = ['buffer', 'dictionary', 'file', 'member']
  let g:deoplete#sources_mail       = ['buffer', 'dictionary', 'file', 'member']

  if !exists('g:loaded_deoplete_ternjs')
    let g:deoplete#omni_patterns = {}
    let g:deoplete#omni_patterns.javascript = '[^. *\t]\.\w*'
  endif
endif
