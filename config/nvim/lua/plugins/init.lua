return {
	{
		'https://github.com/tpope/tpope-vim-abolish',
		cmd = { 'Abolish', 'S', 'Subvert' },
	},
	{ 'https://github.com/tpope/vim-repeat' },
	{ 'https://github.com/wincent/loupe' },
	{
		'https://github.com/christoomey/vim-tmux-navigator',
		lazy = false,
		init = function()
			vim.g.tmux_navigator_disable_when_zoomed = 1
		end,
	},
	{ 'https://github.com/kevinhwang91/nvim-bqf', ft = 'qf' },
}
