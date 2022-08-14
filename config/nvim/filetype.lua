vim.filetype.add {
	extension = {
		mdx = 'markdown.mdx',
	},
	filename = {
		['.envrc'] = 'bash',
		['.stylelintrc'] = 'json',
	},
	pattern = {
		['tsconfig%.?%a*%.json'] = 'jsonc',
	},
}
