# use bash
SHELL:=/bin/bash

# This can be overriden by doing `make DOTFILES=some/path <task>`
DOTFILES="$(HOME)/.dotfiles"
SCRIPTS="$(DOTFILES)/script"
INSTALL="$(SCRIPTS)/install"

all: node python neovim rust macos

install:
	bash <(cat $(INSTALL))

# This is used inside `scripts/install` symlink_files function
# The `-` before commands are to ignore their errors https://stackoverflow.com/a/2670143/213124
symlink:
	stow --restow -vv --ignore ".DS_Store" --target="$(HOME)" --dir="$(DOTFILES)" files

homebrew:
	brew bundle --file="$(DOTFILES)/extra/homebrew/Brewfile"
	brew cleanup
	brew doctor

homebrew-work:
	brew bundle --file="$(DOTFILES)/extra/homebrew/Brewfile.work"

node:
	sh $(SCRIPTS)/node-packages

python:
	sh $(SCRIPTS)/python-packages

rust:
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	rustup component add rls-preview rust-analysis rust-src

# Neovim providers (optional)
neovim:
	gem install neovim
	# pip2 install --upgrade --user pynvim
	# pip3 install --upgrade --user pynvim
	# yarn global add neovim

macos:
	source $(DOTFILES)/extra/macos/.macos

.PHONY: all symlink homebrew homebrew-work node python macos neovim
