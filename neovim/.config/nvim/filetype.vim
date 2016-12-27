" Setting filetypes with high prio, see |new-filetype|
if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  au! BufRead,BufNewFile .{babel,eslint,stylelint,jshint}*rc,\.tern-*,*.json setfiletype json
  au! BufRead,BufNewFile {Gemfile,Brewfile,Rakefile,Vagrantfile,Thorfile,Procfile,Guardfile,config.ru,*.rake} setfiletype ruby
  au! BufNewFile,BufRead .tags setfiletype tags
  au! BufRead,BufNewFile jrnl*.txt,TODO setfiletype markdown
  au! BufRead,BufNewFile *zsh/* setfiletype zsh
  au! BufRead,BufNewFile *.twig setfiletype jinja2
augroup END

