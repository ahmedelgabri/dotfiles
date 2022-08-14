return function()
	local ok, local_config = pcall(require, '_.config.other-local')

	require('other-nvim').setup {
		-- These chars needs to be escaped inside pattern only.
		-- ( ) . % + - * ? [ ^ $
		-- Escaping is done with prepending a % to it
		-- https://github.com/rgroli/other.nvim/issues/4#issuecomment-1108372317
		mappings = vim.tbl_extend('force', {}, ok and local_config or {}),
	}
end
