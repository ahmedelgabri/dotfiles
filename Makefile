# This can be overriden by doing `make DEST=some/path <task>`
DEST = "$(HOME)/.dotfiles"
SCRIPTS = "$(DEST)/script"

all: node python iterm neovim macos

install:
		@./script/install

# This is used inside `scripts/install` symlink_files function
# NOTE: irc/.weechat is not handled with stow, it's handled directly inside bin/mx-init using `--dir` flag
# For some reason stow chokes on ca-bundle.crt since it's an excutable file, will try to figure out later.
symlink:
		@stow --ignore ".DS_Store" --target="$(HOME)" --dir="$(DEST)" \
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
			rss

homebrew:
		@brew bundle --file="$(DEST)/homebrew/Brewfile"
		@brew cleanup
		@brew doctor
		@/usr/local/opt/fzf/install --all

node:
		@sh $(SCRIPTS)/node-packages.sh

python:
		@sh $(SCRIPTS)/python-packages.sh

iterm:
		@sh $(SCRIPTS)/iterm.sh

neovim:
		@gem install neovim

macos:
		@source $(DEST)/macos/.macos

.PHONY: all symlink homebrew node python iterm macos neovim
