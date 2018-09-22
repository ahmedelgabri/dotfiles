# use bash
SHELL:=/bin/bash

# This can be overriden by doing `make DOTFILES=some/path <task>`
DOTFILES="$(HOME)/.dotfiles"
SCRIPTS="$(DOTFILES)/script"
INSTALL="$(SCRIPTS)/install"

all: node python iterm neovim rust macos

install:
	@bash -c "$$(cat $(INSTALL))"

# This is used inside `scripts/install` symlink_files function
# NOTE: irc/.weechat is not handled with stow, it's handled directly inside bin/mx-init using `--dir` flag
# For some reason stow chokes on ca-bundle.crt since it's an excutable file, will try to figure out later.
symlink:
	@stow --restow -vv --ignore ".DS_Store" --target="$(HOME)" --dir="$(DOTFILES)" \
		alacritty \
		ctags \
		git \
		gpg \
		grc \
		hammerspoon \
		irc \
		iterm2 \
		kitty \
		mail \
		misc \
		mpv \
		python \
		ranger \
		rss \
		rtv \
		ssh \
		terminfo \
		tmux \
		vim \
		zsh

homebrew:
	@brew bundle --file="$(DOTFILES)/homebrew/Brewfile"
	@brew cleanup
	@brew doctor
	@/usr/local/opt/fzf/install --all

node:
	@sh $(SCRIPTS)/node-packages

python:
	@sh $(SCRIPTS)/python-packages

rust:
	@curl https://sh.rustup.rs -sSf | sh -s -- -y
	@rustup component add rls-preview rust-analysis rust-src

iterm:
	@sh $(SCRIPTS)/iterm

# Neovim providers (optional)
neovim:
	@gem install neovim
	@pip2 install --user neovim
	@pip3 install --user neovim
	@yarn global add neovim

macos:
	@source $(DOTFILES)/macos/.macos

.PHONY: all symlink homebrew node python iterm macos neovim
