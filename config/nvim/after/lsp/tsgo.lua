return {
	cmd = { 'tsgo', 'lsp', '--stdio' },
	workspace_required = true,
	root_dir = function(_, on_dir)
		-- Don't attach if this is a Deno or Flow project
		if vim.fs.root(0, { '.flowconfig', 'deno.json', 'deno.jsonc' }) then
			return
		end

		local root = vim.fs.root(0, {
			'tsconfig.json',
			'jsconfig.json',
			'package.json',
			'.git',
			vim.api.nvim_buf_get_name(0),
		})

		if root then
			on_dir(root)
		end
	end,
}
