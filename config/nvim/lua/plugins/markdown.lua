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
		'https://github.com/MeanderingProgrammer/markdown.nvim',
		ft = { 'markdown' },
		config = function()
			require('render-markdown').setup {
				render_modes = { 'n', 'c', 'i', 'v', 'V', '\22' },
				-- anti_conceal = { enabled = false },
				sign = { enabled = false },
				indent = { enabled = false },
				dash = { icon = '━' },
				heading = { position = 'inline' },
				code = {
					position = 'right',
					width = 'block',
					min_width = 45,
					border = 'thick',
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
			}
		end,
	},
}
