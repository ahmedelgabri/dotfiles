scriptencoding utf-8

if !exists('g:did_coc_loaded')
  finish
endif

let g:coc_data_home=g:VIMHOME . '/coc'
let g:coc_node_path=exepath('node')

" JSON & YAML schemas http://schemastore.org/json/
let g:coc_user_config = {
      \  'coc': {
      \    'preferences': {
      \      'colorSupport': 0,
      \      'hoverTarget': utils#has_floating_window() ? 'float' : 'echo',
      \    },
      \    'github': {
      \      'filetype': ['gitcommit', 'markdown.ghpull'],
      \    },
      \  },
      \  'suggest': {
      \    'autoTrigger': 'always',
      \    'noselect': 0,
      \    'floatEnable': utils#has_floating_window(),
      \  },
      \  'signature': {
      \    'target': utils#has_floating_window() ? 'float' : 'echo',
      \  },
      \  'diagnostic': {
      \    'errorSign': '',
      \    'warningSign': '',
      \    'infoSign': utils#GetIcon('info'),
      \    'hintSign': utils#GetIcon('hint'),
      \    'enableMessage': 'jump',
      \    'messageTarget': utils#has_floating_window() ? 'float' : 'echo',
      \    'locationlist': 1,
      \    'virtualText': exists('*nvim_buf_set_virtual_text'),
      \    'virtualTextPrefix': ':: ',
      \  },
      \  'python': {
      \    'jediEnabled': 0,
      \    'linting': {
      \      'pylintUseMinimalCheckers': 0
      \    },
      \  },
      \  'rust': {
      \    'clippy_preference': 'on',
      \  },
      \  'json': {
      \     'schemas': [
      \       {
      \         'name': 'tsconfig.json',
      \         'description': 'TypeScript compiler configuration file',
      \         'fileMatch': ['tsconfig.json', 'tsconfig.*.json'],
      \         'url': 'http://json.schemastore.org/tsconfig'
      \       },
      \       {
      \         'name': 'tslint.json',
      \         'description': 'tslint configuration file',
      \         'fileMatch': ['tslint.json'],
      \         'url': 'http://json.schemastore.org/tslint'
      \       },
      \       {
      \         'name': 'lerna.json',
      \         'description': 'Lerna config',
      \         'fileMatch': ['lerna.json'],
      \         'url': 'http://json.schemastore.org/lerna'
      \       },
      \       {
      \         'name': '.babelrc.json',
      \         'description': 'Babel configuration',
      \         'fileMatch': ['.babelrc.json', '.babelrc', 'babel.config.json'],
      \         'url': 'http://json.schemastore.org/lerna'
      \       },
      \       {
      \         'name': '.eslintrc.json',
      \         'description': 'ESLint config',
      \         'fileMatch': ['.eslintrc.json', '.eslintrc'],
      \         'url': 'http://json.schemastore.org/eslintrc'
      \       },
      \       {
      \         'name': 'bsconfig.json',
      \         'description': 'Bucklescript config',
      \         'fileMatch': ['bsconfig.json'],
      \         'url': 'https://bucklescript.github.io/bucklescript/docson/build-schema.json'
      \       },
      \       {
      \         'name': '.prettierrc',
      \         'description': 'Prettier config',
      \         'fileMatch': ['.prettierrc', '.prettierrc.json', 'prettier.config.json'],
      \         'url': 'http://json.schemastore.org/prettierrc'
      \       },
      \       {
      \         'name': 'now.json',
      \         'description': 'ZEIT Now config',
      \         'fileMatch': ['now.json'],
      \         'url': 'http://json.schemastore.org/now'
      \       },
      \       {
      \         'name': '.stylelintrc.json',
      \         'description': 'Stylelint config',
      \         'fileMatch': ['.stylelintrc', '.stylelintrc.json', 'stylelint.config.json'],
      \         'url': 'http://json.schemastore.org/stylelintrc'
      \       },
      \     ]
      \  },
      \  'yaml': {
      \    'schemas': {
      \      'http://json.schemastore.org/github-workflow': '.github/workflows/*.{yml,yaml}',
      \      'http://json.schemastore.org/github-action': '.github/action.{yml,yaml}',
      \      'http://json.schemastore.org/ansible-stable-2.9': 'roles/tasks/*.{yml,yaml}',
      \      'http://json.schemastore.org/prettierrc': '.prettierrc.{yml,yaml}',
      \      'http://json.schemastore.org/stylelintrc': '.stylelintrc.{yml,yaml}',
      \      'http://json.schemastore.org/circleciconfig': '.circleci/**/*.{yml,yaml}',
      \    }
      \  }
      \ }

let s:LSP_CONFIG = [
      \ ['ocaml', {
      \   'command': exepath('ocaml-language-server'),
      \   'args': ['--stdio'],
      \   'filetypes': ['ocaml', 'reason']
      \ }],
      \ ['bash', {
      \   'command': exepath('bash-language-server'),
      \   'args': ['start'],
      \   'filetypes': ['sh', 'bash'],
      \   'ignoredRootPaths': ['~']
      \ }],
      \ ['docker', {
      \   'command': exepath('docker-langserver'),
      \   'args': ['--stdio'],
      \   'filetypes': ['Dockerfile', 'dockerfile']
      \ }],
      \ ['golang', {
      \   'command': exepath('gopls'),
      \   'rootPatterns': ['go.mod', '.vim/', '.git/', '.hg/'],
      \   'filetypes': ['go'],
      \   'initializationOptions': {
      \     'usePlaceholders': 1
      \   }
      \  }],
      \]

let s:languageservers = {}
for [lsp, config] in s:LSP_CONFIG
  " COC chokes on emptykcommands https://github.com/neoclide/coc.nvim/issues/418#issuecomment-462106680"
  let s:not_empty_cmd = !empty(get(config, 'command'))
  if s:not_empty_cmd | let s:languageservers[lsp] = config | endif
endfor

if !empty(s:languageservers)
  call coc#config('languageserver', s:languageservers)
endif

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Use <cr> for confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <silent><expr> <c-space> coc#refresh()

" imap <silent> <C-x><C-o> <Plug>(coc-complete-custom)
imap <silent> <C-x><C-u> <Plug>(coc-complete-custom)
" Use `[c` and `]c` for navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nmap <leader>r <Plug>(coc-rename)
" Use K for show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

augroup MY_COC
  autocmd!
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  autocmd CursorHold * silent call CocActionAsync('highlight')
  autocmd BufWritePost coc.vim source % | CocRestart
  autocmd BufWritePost {coc-settings,tsconfig}.json,.flowconfig CocRestart
  autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
augroup end
