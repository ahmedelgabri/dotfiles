return {
	root_dir = function(_bufnr, on_dir)
		local root = vim.fs.root(0, { 'deno.json', 'deno.jsonc' })

		if root then
			on_dir(root)
		end
	end,
}
