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
			vim.cmd [[Lazy load markdown-preview.nvim]]
			vim.fn['mkdp#util#install']()
		end,
	},
	{
		'https://github.com/MeanderingProgrammer/markdown.nvim',
		ft = { 'markdown' },
		config = function()
			require('render-markdown').setup {}
		end,
	},
}
