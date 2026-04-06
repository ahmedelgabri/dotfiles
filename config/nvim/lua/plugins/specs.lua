return {
	-- Core utilities
	'https://github.com/tpope/vim-repeat',
	'https://github.com/alexghergh/nvim-tmux-navigation',
	{
		src = 'https://github.com/saghen/blink.indent',
		name = 'blink.indent',
		data = { lazy = true },
	},
	'https://github.com/nvim-mini/mini.nvim',
	'https://github.com/folke/snacks.nvim',
	'https://github.com/stevearc/oil.nvim',
	'https://github.com/ibhagwan/fzf-lua',
	{ src = 'https://github.com/wincent/loupe', data = { lazy = true } },

	-- Treesitter
	{
		src = 'https://github.com/nvim-treesitter/nvim-treesitter',
		version = 'main',
		data = {
			run = function()
				vim.cmd 'TSUpdate'
			end,
		},
	},
	{
		src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
		version = 'main',
	},
	'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
	'https://github.com/windwp/nvim-ts-autotag',
	{
		src = 'https://github.com/HiPhish/rainbow-delimiters.nvim',
		data = { lazy = true },
	},

	-- Git
	'https://github.com/tpope/vim-rhubarb',
	'https://github.com/tpope/vim-fugitive',
	'https://github.com/Tronikelis/conflict-marker.nvim',
	{ src = 'https://github.com/jez/vim-github-hub', data = { lazy = true } },
	'https://github.com/nvim-lua/plenary.nvim',
	{ src = 'https://github.com/MunifTanjim/nui.nvim', data = { lazy = true } },
	{
		src = 'https://github.com/esmuellert/codediff.nvim',
		data = { lazy = true },
	},

	-- Search / navigation helpers
	{
		src = 'https://github.com/junegunn/fzf',
		name = 'fzf',
		data = { lazy = true },
	},
	{ src = 'https://github.com/kevinhwang91/nvim-bqf', data = { lazy = true } },
	{ src = 'https://github.com/jbyuki/venn.nvim', data = { lazy = true } },
	{ src = 'https://github.com/fladson/vim-kitty', data = { lazy = true } },
	{
		src = 'https://github.com/MagicDuck/grug-far.nvim',
		data = { lazy = true },
	},
	{ src = 'https://github.com/hedyhli/outline.nvim', data = { lazy = true } },

	-- LSP / formatting
	'https://github.com/b0o/SchemaStore.nvim',
	{ src = 'https://github.com/SmiteshP/nvim-navic', data = { lazy = true } },
	'https://github.com/neovim/nvim-lspconfig',
	{ src = 'https://github.com/nvimtools/none-ls.nvim', data = { lazy = true } },
	'https://github.com/stevearc/conform.nvim',

	-- Completion / editing
	{
		src = 'https://github.com/L3MON4D3/LuaSnip',
		data = {
			lazy = true,
			run = function(plugin)
				vim.fn.system { 'make', '-C', plugin.path, 'install_jsregexp' }
			end,
		},
	},
	{
		src = 'https://github.com/rafamadriz/friendly-snippets',
		data = { lazy = true },
	},
	{
		src = 'https://github.com/Saghen/blink.cmp',
		name = 'blink.cmp',
		version = vim.version.range '1.x',
		data = { lazy = true },
	},
	{ src = 'https://github.com/moyiz/blink-emoji.nvim', data = { lazy = true } },
	{
		src = 'https://github.com/xzbdmw/colorful-menu.nvim',
		data = { lazy = true },
	},
	{ src = 'https://github.com/windwp/nvim-autopairs', data = { lazy = true } },

	-- Markdown / notes
	'https://github.com/davidmh/mdx.nvim',
	'https://github.com/zk-org/zk-nvim',
	{
		src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
		data = { lazy = true },
	},
	{
		src = 'https://github.com/YousefHadder/markdown-plus.nvim',
		data = { lazy = true },
	},
	{
		src = 'https://github.com/obsidian-nvim/obsidian.nvim',
		version = vim.version.range '*',
		data = { lazy = true },
	},

	-- AI / misc tools
	{ src = 'https://github.com/folke/sidekick.nvim', data = { lazy = true } },
	{ src = 'https://github.com/kawre/leetcode.nvim', data = { lazy = true } },
}
