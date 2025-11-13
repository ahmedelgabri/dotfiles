return {
	cmd = { 'tsgo', 'lsp', '--stdio' },
	workspace_required = true,
	root_dir = function(_, on_dir)
		on_dir(
			not vim.fs.root(0, { '.flowconfig', 'deno.json', 'deno.jsonc' })
				and vim.fs.root(0, {
					'tsconfig.json',
					'jsconfig.json',
					'package.json',
					'.git',
					vim.api.nvim_buf_get_name(0),
				})
		)
	end,
}
