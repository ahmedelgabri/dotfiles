" :h new-filetype
if exists('did_load_filetypes')
  finish
endif

augroup filetypedetect
  autocmd!
  autocmd BufRead,BufNewFile .{stylelint,jshint}rc,.tern-* setfiletype json
  autocmd BufRead,BufNewFile {tsconfig,tsconfig.*}.json setfiletype jsonc
  autocmd BufRead,BufNewFile .prettierrc setfiletype yaml
  autocmd BufRead,BufNewFile .envrc setfiletype bash
  autocmd BufRead,BufNewFile *.nix setfiletype nix
  autocmd BufRead,BufNewFile *.res setfiletype rescript
augroup END
