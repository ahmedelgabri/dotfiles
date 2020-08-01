" :h new-filetype
if exists('did_load_filetypes')
  finish
endif

augroup filetypedetect
  autocmd!
  autocmd BufRead,BufNewFile jrnl*.txt,TODO setfiletype markdown
  autocmd BufRead,BufNewFile {Gemfile,Brewfile,Rakefile,Vagrantfile,Thorfile,Procfile,Guardfile,config.ru,*.rake} setfiletype ruby
  autocmd BufRead,BufNewFile .{babel,eslint,stylelint,jshint}rc,.tern-* setfiletype json
  autocmd BufRead,BufNewFile .prettierrc setfiletype yaml
  autocmd BufRead,BufNewFile .envrc setfiletype bash
  autocmd BufRead,BufNewFile *.conf setfiletype conf
augroup END
