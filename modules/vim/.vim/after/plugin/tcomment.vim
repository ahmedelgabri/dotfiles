" Prevent tcomment from making a zillion mappings (we just want the operator).
let g:tcomment_mapleader1=''
let g:tcomment_mapleader2=''
let g:tcomment_mapleader_comment_anyway=''
let g:tcomment_textobject_inlinecomment=''
" The default (g<) is a bit awkward to type.
let g:tcomment_mapleader_uncomment_anyway='gu'

"  Uncomment a line; mirrors gcc (which comments/toggles a line).
nmap guu <Plug>TComment_Uncommentc
xmap gu <Plug>TComment_Uncommentc
