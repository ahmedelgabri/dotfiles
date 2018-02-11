augroup FT_RUBY
  au!
  au BufRead,BufNewFile {Gemfile,Brewfile,Rakefile,Vagrantfile,Thorfile,Procfile,Guardfile,config.ru,*.rake} setl ft=ruby
augroup END

