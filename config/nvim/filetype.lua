vim.filetype.add {
	extension = {
		mdc = 'markdown',
		log = 'log',
		env = 'dotenv',
		sb = 'scheme', -- Apple sandbox rules
		['code-workspace'] = 'json5',
		base = 'yaml.obsidian',
		mts = 'typescript',
		cts = 'typescript',
	},
	filename = {
		['.envrc'] = 'bash',
		['.env'] = 'dotenv',
		['.stylelintrc'] = 'json',
		['.stylelintignore'] = 'gitignore',
		['.eslintrc.json'] = 'json5',
		['.luarc.json'] = 'json5',
		['.oxlintrc.json'] = 'json5',
		Brewfile = 'ruby',
		['turbo.json'] = 'json5',
		['nx.json'] = 'json5',
		PULLREQ_EDITMSG = 'markdown.ghpull',
		ISSUE_EDITMSG = 'markdown.ghissue',
		RELEASE_EDITMSG = 'markdown.ghrelease',
	},
	pattern = {
		['[jt]sconfig*.json'] = 'json5',
		['.*/%.vscode/.*%.json'] = 'json5',
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

-- jsonc treesitter parser is not actively maintained
vim.api.nvim_create_autocmd('FileType', {
	pattern = 'jsonc',
	callback = function(args)
		vim.bo[args.buf].filetype = 'json5'
	end,
})
