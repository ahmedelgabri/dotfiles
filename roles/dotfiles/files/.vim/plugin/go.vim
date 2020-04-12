" Coc will handle this with `gd`
let g:go_def_mapping_enabled = exists(':CocInfo') ? 0 : 1

if !exists('CocInfo')
  " They don't accept absolute path, must be a string only for the tool itself.
  let g:go_def_mode = 'gopls'
  let g:go_info_mode = 'gopls'
endif
