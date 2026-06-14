-- Markdown plugins
local pack = require '_.pack'

pack.add {
	{
		src = 'https://github.com/davidmh/mdx.nvim',
		ft = { 'markdown', 'markdown.mdx', 'mdx' },
	},
	{
		src = 'https://github.com/zk-org/zk-nvim',
		config = function()
			require('zk').setup {
				picker = 'fzf_lua',
				lsp = {
					auto_attach = {
						enabled = false,
					},
				},
			}

			require('_.notes').setup()
		end,
	},
	{
		src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
		ft = { 'markdown', 'md', 'codecompanion' },
		config = function()
			require('render-markdown').setup {
				file_types = { 'markdown', 'md', 'codecompanion' },
				render_modes = { 'n', 'no', 'c', 't', 'i', 'ic' },
				code = {
					sign = false,
					border = 'thin',
					position = 'right',
					width = 'block',
					above = '▁',
					below = '▔',
					language_left = '█',
					language_right = '█',
					language_border = '▁',
					left_pad = 1,
					right_pad = 1,
				},
				heading = {
					sign = false,
					width = 'block',
					left_pad = 1,
					right_pad = 0,
					position = 'inline',
					icons = { '󰉫  ', '󰉬  ', '󰉭  ', '󰉮  ', '󰉯  ', '󰉰  ' },
				},
			}
		end,
	},
	{
		src = 'https://github.com/YousefHadder/markdown-plus.nvim',
		ft = { 'markdown', 'txt', 'text' },
		config = function()
			require('markdown-plus').setup {
				filetypes = { 'markdown', 'text', 'txt' },
			}
		end,
	},
}
