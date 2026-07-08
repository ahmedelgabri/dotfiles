local pack = require '_.pack'

pack.add {
	{
		src = 'https://github.com/mfussenegger/nvim-lint',
		ft = { 'zsh', 'nix', 'dockerfile', 'dotenv', 'yaml' },
		config = function()
			local au = require '_.utils.au'
			local lint = require 'lint'

			lint.linters.dotenv_linter.args = {
				'check',
				'--ignore-checks',
				'UnorderedKey',
				'--quiet',
			}

			lint.linters_by_ft = {
				zsh = { 'zsh' },
				dockerfile = { 'hadolint' },
				nix = { 'statix' },
				dotenv = { 'dotenv_linter' },
				-- GitHub workflow files get this filetype via filetype.lua, so
				-- actionlint only runs inside .github/
				['yaml.github'] = { 'actionlint' },
			}

			au.augroup('__LINT__', {
				{
					event = { 'BufReadPost', 'BufWritePost' },
					callback = function()
						lint.try_lint()
					end,
				},
			})

			-- the FileType event that loads this plugin has already fired for
			-- the current buffer, so lint it explicitly once
			lint.try_lint()
		end,
	},
}
