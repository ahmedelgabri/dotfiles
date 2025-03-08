return {
	{
		'https://github.com/iamcco/markdown-preview.nvim',
		cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
		ft = { 'markdown' },
		keys = {
			{
				'<leader>p',
				vim.cmd.MarkdownPreview,
				noremap = true,
				buffer = true,
				desc = '[P]review Markdown',
			},
		},
		build = function()
			require('lazy').load { plugins = { 'markdown-preview.nvim' } }
			vim.fn['mkdp#util#install']()
		end,
	},
	{
		'https://github.com/MeanderingProgrammer/render-markdown.nvim',
		ft = { 'markdown', 'codecompanion', 'gitcommit' },
		opts = function(_, opts)
			return vim.tbl_deep_extend('force', opts or {}, {
				completions = {
					lsp = {
						enabled = true,
					},
				},
				render_modes = { 'n', 'c', 'i', 'v', 'V', '\22', 't' },
				-- anti_conceal = { enabled = false },
				sign = { enabled = false },
				indent = { enabled = false },
				dash = { icon = '🬋' },
				heading = { position = 'inline' },
				code = {
					position = 'right',
					width = 'block',
					min_width = 45,
					border = 'thick',
					left_pad = 2,
					right_pad = 2,
				},
				bullet = { right_pad = 1 },
				link = {
					custom = {
						github = {
							pattern = '^http[s]?://w*%.?github%.com/.*',
							icon = require('mini.icons').get('directory', '.github') .. ' ',
							highlight = 'RenderMarkdownGithubLink',
						},
						file = {
							pattern = '^file:',
							icon = "'",
							highlight = 'RenderMarkdownFileLink',
						},
						youtube = {
							pattern = '^http[s]?://www%.youtube%.com/.*',
							icon = "'",
							highlight = 'RenderMarkdownYoutubeLink',
						},
					},
				},
				pipe_table = {
					preset = 'heavy',
					cell = 'trimmed',
				},
				checkbox = {
					-- position = 'overlay',
					checked = { scope_highlight = '@markup.strikethrough' },
				},
			})
		end,
	},
	{
		'https://github.com/obsidian-nvim/obsidian.nvim',
		-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
		event = {
			string.format('BufReadPre %s/*.md', vim.env.NOTES_DIR),
			string.format('BufNewFile %s/*.md', vim.env.NOTES_DIR),
		},
		dependencies = {
			-- Required.
			'https://github.com/nvim-lua/plenary.nvim',
		},
		opts = function(_, opts)
			return vim.tbl_deep_extend('force', opts or {}, {
				workspaces = {
					{
						name = 'notes',
						path = vim.env.NOTES_DIR,
					},
				},

				daily_notes = {
					folder = 'journal',
					default_tags = { 'daily-notes' },
					template = vim.fn.expand '~/.config/zk/templates/journal.md',
				},

				completion = {
					nvim_cmp = false,
					blink = false,
				},

				picker = {
					name = 'snacks.pick',
				},

				ui = {
					enable = false,
				},

				attachments = {
					img_folder = 'assets',
				},
			})
		end,
	},
}
