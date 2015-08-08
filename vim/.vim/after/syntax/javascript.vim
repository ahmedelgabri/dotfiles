if !has('conceal')
  finish
endif

set conceallevel=2

" syntax keyword jsConcealThis this conceal cchar=@
syntax match jsConcealFunction /\<function\>/ skipwhite conceal cchar=ƒ

" hi def link jsConcealFunction jsFunc
hi def link jsConcealFunction javaScriptIdentifier
hi Conceal ctermfg=245
