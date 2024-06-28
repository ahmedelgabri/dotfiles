if not vim.filetype then
	return
end

vim.filetype.add {
	extension = {
		mdx = 'mdx',
		http = 'http',
		log = 'log',
		conf = 'conf',
		env = 'dotenv',
		['code-workspace'] = 'jsonc',
	},
	filename = {
		['.envrc'] = 'bash',
		['.env'] = 'dotenv',
		['.stylelintrc'] = 'json',
		Brewfile = 'ruby',
		['turbo.json'] = 'jsonc',
		['nx.json'] = 'jsonc',
		PULLREQ_EDITMSG = 'markdown.ghpull',
		ISSUE_EDITMSG = 'markdown.ghissue',
		RELEASE_EDITMSG = 'markdown.ghrelease',
	},
	pattern = {
		['tsconfig*.json'] = 'jsonc',
		['.*/%.vscode/.*%.json'] = 'jsonc',
		-- INFO: Match filenames like - ".env.example", ".env.local" and so on
		-- needed to make dotenv-linter with null-ls works correctly
		['%.env%.[%w_.-]+'] = 'dotenv',
		['.*%.gradle'] = 'groovy',
		['.*/%.github/.*%.y*ml'] = 'yaml.github',
	},
}
