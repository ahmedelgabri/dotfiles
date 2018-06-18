" :h new-filetype
if exists('did_load_filetypes')
  finish
endif

augroup filetypedetect
  autocmd!
  autocmd BufRead,BufNewFile jrnl*.txt,TODO set ft=markdown
  autocmd BufRead,BufNewFile {Gemfile,Brewfile,Rakefile,Vagrantfile,Thorfile,Procfile,Guardfile,config.ru,*.rake} setl ft=ruby
  autocmd BufRead,BufNewFile .{babel,eslint,stylelint,jshint,prettier}rc,.tern-* setl ft=json
augroup END
