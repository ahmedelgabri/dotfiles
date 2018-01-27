let s:initrc=expand('~/.dotfiles/vim/.config/nvim/init.vim')

if filereadable(s:initrc)
  execute 'source '. s:initrc
endif
