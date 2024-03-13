return {
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
		vim.fn['mkdp#util#install']()
	end,
}
