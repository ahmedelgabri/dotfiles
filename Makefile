# use bash
SHELL:=/bin/bash

# This can be overriden by doing `make DEST=some/path <task>`
DEST="$(HOME)/.dotfiles"
SCRIPTS="$(DEST)/script"
INSTALL="$(SCRIPTS)/install"

all: node python iterm neovim rust macos

install:
	@bash -c "$$(cat $(INSTALL))"

# This is used inside `scripts/install` symlink_files function
# NOTE: irc/.weechat is not handled with stow, it's handled directly inside bin/mx-init using `--dir` flag
# For some reason stow chokes on ca-bundle.crt since it's an excutable file, will try to figure out later.
symlink:
	@stow --restow --verbose --ignore ".DS_Store" --target="$(HOME)" --dir="$(DEST)" \
		ctags \
		git \
		grc \
		hammerspoon \
		iterm2 \
		mail \
		misc \
		rss \
		rtv \
		terminfo \
		tmux \
		vim \
		zsh

homebrew:
	@brew bundle --file="$(DEST)/homebrew/Brewfile"
	@brew cleanup
	@brew doctor
	@/usr/local/opt/fzf/install --all

node:
	@sh $(SCRIPTS)/node-packages

python:
	@sh $(SCRIPTS)/python-packages

rust:
	@curl https://sh.rustup.rs -sSf | sh -s -- -y

iterm:
	@sh $(SCRIPTS)/iterm

# Neovim providers (optional)
neovim:
	@gem install neovim
	@pip2 install --user neovim
	@pip3 install --user neovim
	@yarn global add neovim

macos:
	@source $(DEST)/macos/.macos

.PHONY: all symlink homebrew node python iterm macos neovim
