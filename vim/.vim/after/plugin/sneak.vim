let g:sneak#label        = 1 " move to next match immediately, tab through stuff
let g:sneak#absolute_dir = 1 " always go the same way.
let g:sneak#use_ic_scs   = 1 " case dependent on ignorecase+smartcase
" let g:sneak#label_esc    = "<c-c>"

map s <Plug>Sneak_s
map S <Plug>Sneak_S
map f <Plug>Sneak_f
map F <Plug>Sneak_F
map t <Plug>Sneak_t
map T <Plug>Sneak_T

