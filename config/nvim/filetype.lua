vim.filetype.add {
	extension = {
		mdx = 'markdown.mdx',
	},
	filename = {
		['.envrc'] = 'bash',
		['.stylelintrc'] = 'json',
	},
	pattern = {
		['tsconfig.*%.json'] = 'jsonc',
	},
}
