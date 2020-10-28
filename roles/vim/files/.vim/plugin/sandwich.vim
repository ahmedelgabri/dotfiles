if exists('g:loaded_sandwich')
  finish
endif

runtime macros/sandwich/keymap/surround.vim

let g:sandwich#recipes += [
      \   {'buns': ['/\*\s*', '\s*\*/'], 'regex': 1, 'filetype': ['typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascriptreact', 'javascript.jsx'], 'input': ['/']},
      \   {'buns': ['${', '}'], 'filetype': ['typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascriptreact', 'javascript.jsx', 'zsh', 'bash', 'shell'], 'input': ['$']}
      \ ]
