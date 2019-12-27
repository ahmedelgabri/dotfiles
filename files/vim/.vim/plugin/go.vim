" Coc will handle this with `gd`
let g:go_def_mapping_enabled = exists(':CocInfo') ? 0 : 1

if !exists('CocInfo')
  let g:go_def_mode = exepath('gopls')
  let g:go_info_mode = exepath('gopls')
endif
