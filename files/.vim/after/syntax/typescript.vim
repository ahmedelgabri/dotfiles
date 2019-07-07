scriptencoding utf-8

" remove the keywords. we'll re-add them below
syntax clear typescriptFuncImpl typescriptFuncKeyword typescriptAsyncFuncKeyword

syntax keyword typescriptFuncImpl function conceal cchar=ƒ
syntax keyword typescriptFuncKeyword function conceal cchar=ƒ
syntax keyword typescriptAsyncFuncKeyword function conceal cchar=ƒ
