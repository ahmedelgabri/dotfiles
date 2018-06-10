scriptencoding utf-8

syntax match jsFunction /\<function\>/ skipwhite skipempty nextgroup=jsGenerator,jsFuncName,jsFuncArgs,jsFlowFunctionGroup skipwhite conceal cchar=ƒ
