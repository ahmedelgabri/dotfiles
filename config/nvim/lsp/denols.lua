return {
	root_dir = function(_bufnr, on_dir)
		on_dir(vim.fs.root(0, { 'deno.json', 'deno.jsonc' }))
	end,
}
