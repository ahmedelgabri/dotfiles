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
		-- .env.* files to match the filetype for .env, needed also to make sure
		-- dotenv-linter with null-ls works correctly
		['%.env%..*'] = 'sh',
	},
}
