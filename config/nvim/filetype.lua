vim.filetype.add {
	extension = {
		mdx = 'mdx',
		log = 'log',
		env = 'dotenv',
		sb = 'scheme', -- Apple sandbox rules
		['code-workspace'] = 'jsonc',
	},
	filename = {
		['.envrc'] = 'bash',
		['.env'] = 'dotenv',
		['.stylelintrc'] = 'json',
		['.stylelintignore'] = 'gitignore',
		['.eslintrc.json'] = 'jsonc',
		['.luarc.json'] = 'jsonc',
		['.oxlintrc.json'] = 'jsonc',
		Brewfile = 'ruby',
		['turbo.json'] = 'jsonc',
		['nx.json'] = 'jsonc',
		PULLREQ_EDITMSG = 'markdown.ghpull',
		ISSUE_EDITMSG = 'markdown.ghissue',
		RELEASE_EDITMSG = 'markdown.ghrelease',
	},
	pattern = {
		['[jt]sconfig*.json'] = 'jsonc',
		['.*/%.vscode/.*%.json'] = 'jsonc',
		-- INFO: Match filenames like - ".env.example", ".env.local" and so on
		-- needed to make dotenv-linter with null-ls works correctly
		['%.env%.[%w_.-]+'] = 'dotenv',
		['.*%.gradle'] = 'groovy',
		['.*/%.github/.*%.y*ml'] = 'yaml.github',
		-- For dockder compose-language-service
		['compose.y.?ml'] = 'yaml.docker-compose',
		['docker%-compose%.y.?ml'] = 'yaml.docker-compose',
	},
}
