all: homebrew node python iterm neovim

install:
		@./script/install

# This is used inside `scripts/install` symlink_files function
# NOTE: irc/.weechat is not handled with stow, it's handled directly inise bin/mx-init
# using `--dir` flag
symlink:
		@stow --ignore ".DS_Store" --target="$(HOME)" --dir="$(HOME)/.dotfiles" \
			misc \
			ctags \
			curl \
			git \
			grc \
			hammerspoon \
			iterm2 \
			mail \
			neovim \
			python \
			ruby \
			terminfo \
			tmux \
			vim \
			zsh \
			tig \
			newsbeuter

homebrew:
		@brew bundle --file="$(HOME)/.dotfiles/homebrew/Brewfile"
		@brew cleanup
		@brew doctor
		@/usr/local/opt/fzf/install --all

node:
		@sh ./script/node-packages.sh

python:
		@sh ./script/python-packages.sh

iterm:
		@sh ./script/iterm.sh

neovim:
		@gem install neovim

macos:
		@source $(HOME)/.dotfiles/macos/.macos

.PHONY: all symlink homebrew node python iterm macos neovim
