# Better C-r with atuin history database but with better fuzzy search using fzf
# Ref: https://github.com/atuinsh/atuin/issues/68#issuecomment-1567410629 with some modifications
if which atuin &>/dev/null; then
	fzf-atuin-history-widget() {
		local selected num
		setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null

		local atuin_opts="--print0 --cmd-only"
		local fzf_opts=(
			"--height=${FZF_TMUX_HEIGHT:-80%}"
			"--tac"
			"--nth=2..,.."
			"--tiebreak=index"
			"--preview=echo {}"
			"--preview-window=down:2:hidden:wrap"
			"--bind=?:toggle-preview"
			"--query=${LBUFFER}"
			"--no-multi"
			"--highlight-line"
			"--read0"
			"--bind=ctrl-d:reload(atuin search $atuin_opts -c $PWD),ctrl-r:reload(atuin search $atuin_opts)"
		)

		selected=$(eval "atuin search ${atuin_opts}" | fzf "${fzf_opts[@]}")

		local ret=$?
		if [ -n "$selected" ]; then
			LBUFFER="${selected}"
		fi

		zle reset-prompt
		return $ret
	}

	zle -N fzf-atuin-history-widget
	bindkey '^R' fzf-atuin-history-widget
fi

# zoxide with fuzzy search
# https://github.com/ajeetdsouza/zoxide/issues/34#issuecomment-2099442403
zf() {
	cd $(zoxide query --list --score | fzf --height 40% --layout reverse --info inline --border --preview "eza --all --group-directories-first --header --long --no-user --no-permissions --color=always {2}" --no-sort | awk '{print $2}')
}

# Avoid ssh issues with ssh and terminfo with new terminal apps
[[ $TERM == "xterm-kitty" ]] || [[ $TERM == "xterm-ghostty" ]] && alias ssh="TERM=xterm-256color ssh"
