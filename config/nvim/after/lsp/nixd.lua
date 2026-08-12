-- The logical host name (the flake attribute) is the basename of
-- $HOST_CONFIGS (~/.local/share/<host>). Don't use vim.fn.hostname(): the MDM
-- owns the machine name on work hosts and renames it to the serial number.
local host = vim.env.HOST_CONFIGS and vim.fs.basename(vim.env.HOST_CONFIGS)
	or vim.fn.hostname()

return {
	-- https://github.com/nix-community/nixvim/issues/2390#issuecomment-2408101568
	-- offset_encoding = 'utf-8',
	settings = {
		nixd = {
			nixpkgs = {
				expr = vim.fs.root(0, { 'shell.nix' }) ~= nil
						and 'import <nixpkgs> { }'
					or string.format(
						'import (builtins.getFlake "%s").inputs.nixpkgs { }',
						vim.fs.root(0, { 'flake.nix' }) or vim.fn.expand '$DOTFILES'
					),
			},
			formatting = {
				command = { 'nixfmt' },
			},
			options = vim.tbl_extend('force', {
				-- home_manager = {
				-- 	expr = string.format(
				-- 		'(builtins.getFlake "%s").homeConfigurations.%s.options',
				--    vim.fs.root(0, { 'flake.nix' }) or vim.fn.expand '$DOTFILES',
				-- 		vim.fn.hostname()
				-- 	),
				-- },
			}, vim.fn.has 'macunix' and {
				['nix-darwin'] = {
					expr = string.format(
						'(builtins.getFlake "%s").darwinConfigurations.%s.options',
						vim.fs.root(0, { 'flake.nix' }) or vim.fn.expand '$DOTFILES',
						host
					),
				},
			} or {
				nixos = {
					expr = string.format(
						'(builtins.getFlake "%s").nixosConfigurations.%s.options',
						vim.fs.root(0, { 'flake.nix' }) or vim.fn.expand '$DOTFILES',
						host
					),
				},
			}),
		},
	},
}
