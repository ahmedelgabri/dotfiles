# use bash
SHELL:=/bin/bash

# This can be overriden by doing `make DOTFILES=some/path <task>`
DOTFILES="$(HOME)/.dotfiles"
SCRIPTS="$(DOTFILES)/script"
INSTALL="$(SCRIPTS)/install"
STOW_PACKAGES= alacritty \
			   ctags \
			   git \
			   gpg \
			   hammerspoon \
			   irc \
			   kitty \
			   mail \
			   mpv \
			   node \
			   python \
			   rss \
			   shell \
			   ssh \
			   tmux \
			   tuir \
			   utils \
			   vim

all: mail node python neovim rust macos

install:
	bash <(cat $(INSTALL))

debug:
	bash -x <(cat $(INSTALL))

symlink:
	stow --restow -vv --ignore ".DS_Store" --ignore ".+.local" --target="$(HOME)" --dir="$(DOTFILES)/files" $(STOW_PACKAGES)

# Context: https://github.com/aspiers/stow/issues/29
prepare:
	mkdir -p "$(HOME)/.mail/{Personal,Work,.notmuch}" \
		"$(HOME)/.mutt/tmp" \
		"$(HOME)/.ssh" \
		"$(HOME)/.config/{weechat,zsh,mpv,gnupg,python,ripgrep,bat,newsboat}" \
		"$(HOME)/Library/LaunchAgents"

# This command runs only once, on the initial setup of a machine.
#
# `stow` by default doesn't override files/folders
# The `--adopt` flag will take any files from `$HOME` in this case that
# conflicts with my files, put them in the repo & link them.
# Which means that git will show files as changed, so we revert the changes
# to get our changes & everything should be working as expected
initial-symlink: prepare
	stow --adopt -vv --ignore ".DS_Store" --ignore ".+.local" --target="$(HOME)" --dir="$(DOTFILES)/files" $(STOW_PACKAGES)
	cd "$(DOTFILES)" && git stash -u; git reset --hard origin/master && git stash pop

gpg: symlink
	# Fix gpg folder/file permissions after symlinking
	chmod 700 $(HOME)/.config/gnupg && chmod 600 $(HOME)/.config/gnupg/*

homebrew:
	brew bundle --file="$(DOTFILES)/extra/homebrew/Brewfile.shared"

homebrew-personal: homebrew
	brew bundle --file="$(DOTFILES)/extra/homebrew/Brewfile.personal"
	brew cleanup
	brew doctor

homebrew-work: homebrew
	brew bundle --file="$(DOTFILES)/extra/homebrew/Brewfile.work"
	brew cleanup
	brew doctor

mail:
	node $(DOTFILES)/files/mail/.mutt/scripts/setup

node:
	sh $(SCRIPTS)/node-packages

python:
	sh $(SCRIPTS)/python-packages

rust:
	curl https://sh.rustup.rs -sSf | sh -s -- -y --profile complete # I need complete for rls & LSP support

# Neovim providers (optional)
neovim:
	gem install neovim
	# pip2 install --upgrade --user pynvim
	# pip3 install --upgrade --user pynvim
	# yarn global add neovim

macos:
	source $(DOTFILES)/extra/macos/.macos

.PHONY: all symlink homebrew homebrew-work node python macos neovim
