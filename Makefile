all: homebrew node python iterm

install:
		@./script/install

symlink:
		@./script/symlink

homebrew:
		@brew update
		@brew bundle --file=~/.dotfiles/homebrew/Brewfile
		@brew cleanup
		@brew doctor

node:
		@sh ./node/packages.sh

python:
		@sh ./python/packages.sh

iterm:
		@sh ./iterm2/themes.sh

macos:
		@source ~/.dotfiles/macos/macos.local

.PHONY: symlink homebrew node python iterm macos
