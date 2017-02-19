all: homebrew node python iterm

install:
		@./script/install

# This is used inside `scripts/install` symlink_files function
symlink:
		@stow --ignore ".DS_Store" --target="$(HOME)" --dir="$(HOME)/.dotfiles" \
			misc \
			ctags \
			curl \
			git \
			grc \
			hammerspoon \
			irc \
			iterm2 \
			mail \
			neovim \
			python \
			ruby \
			terminfo \
			tmux \
			vim \
			zsh

homebrew:
		@brew bundle --file="$(HOME)/.dotfiles/homebrew/Brewfile"
		@brew cleanup
		@brew doctor

node:
		@sh ./script/node-packages.sh

python:
		@sh ./script/python-packages.sh

iterm:
		@sh ./iterm2/themes.sh

macos:
		@source $(HOME)/.dotfiles/macos/.macos

.PHONY: symlink homebrew node python iterm macos
