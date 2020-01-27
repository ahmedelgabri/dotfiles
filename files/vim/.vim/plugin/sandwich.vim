if exists('g:loaded_sandwich')
  finish
endif

runtime macros/sandwich/keymap/surround.vim

" Copy sandwich default recipes
let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
let g:sandwich#recipes += [
      \   {'buns': ['/\*\s*', '\s*\*/'], 'regex': 1, 'filetype': ['typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascriptreact', 'javascript.jsx'], 'input': ['/']},
      \ ]
