scriptencoding utf-8

let g:vsnip_snippet_dir=stdpath('config').'/vsnip'

" Expand
imap <expr> <C-j> vsnip#expandable() ? '<Plug>(vsnip-expand)' : '<C-j>'
smap <expr> <C-j> vsnip#expandable() ? '<Plug>(vsnip-expand)' : '<C-j>'

" Expand or jump
imap <expr> <C-l> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'

" Select or cut text to use as $TM_SELECTED_TEXT in the next snippet.
" See https://github.com/hrsh7th/vim-vsnip/pull/50
" nmap        <C-l>   <Plug>(vsnip-select-text)
" xmap        <C-l>   <Plug>(vsnip-select-text)
" smap        <C-l>   <Plug>(vsnip-select-text)
" nmap        <C-j>   <Plug>(vsnip-cut-text)
" xmap        <C-j>   <Plug>(vsnip-cut-text)
" smap        <C-j>   <Plug>(vsnip-cut-text)

let g:vsnip_filetypes = {}
" Order is important because if two snippets have the same triggers the LAST one will take precendence
let g:vsnip_filetypes['typescript.tsx'] = ['javascript']
let g:vsnip_filetypes['jinja'] = ['html', 'htmldjango']
let g:vsnip_filetypes['jinja2'] = ['html', 'htmldjango']
let g:vsnip_filetypes['html.twig'] = ['htmldjango']
