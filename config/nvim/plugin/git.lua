local pack = require '_.pack'

pack.add {
	{ src = 'https://github.com/tpope/vim-rhubarb', event = { 'UIEnter' } },
	{ src = 'https://github.com/tpope/vim-fugitive', event = { 'UIEnter' } },
	-- { src = 'https://github.com/NicolasGB/jj.nvim' },
	-- { src = 'https://github.com/jceb/jiejie.nvim', event = { 'UIEnter' } },
	{
		src = 'https://github.com/martintrojer/fugitive-core.nvim',
		event = { 'UIEnter' },
	},
	{
		src = 'https://github.com/martintrojer/jj-fugitive',
		event = { 'UIEnter' },
	},
	{
		src = 'https://github.com/barrettruth/diffs.nvim',
		config = function()
			vim.g.diffs = {
				integrations = {
					fugitive = true,
				},
			}
		end,
	},
	{
		src = 'https://github.com/Tronikelis/conflict-marker.nvim',
		event = { 'UIEnter' },
		config = function()
			vim.keymap.set({ 'n', 'v' }, '<leader>gb', ':GBrowse<cr>', {
				desc = '[G]it [B]rowse file',
			})
			vim.keymap.set({ 'n', 'v' }, '<leader>gs', ':Git<cr>', {
				desc = '[G]it [S]tatus',
			})

			local fugitive_group =
				vim.api.nvim_create_augroup('__my_fugitive__', { clear = true })

			-- http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
			vim.api.nvim_create_autocmd('BufReadPost', {
				group = fugitive_group,
				pattern = 'fugitive://*',
				callback = function()
					vim.bo.bufhidden = 'delete'
				end,
			})

			vim.api.nvim_create_autocmd('User', {
				group = fugitive_group,
				pattern = 'fugitive',
				command = [[if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' | nnoremap <buffer> .. :edit %:h<CR> | endif]],
			})

			require('conflict-marker').setup {
				on_attach = function(conflict)
					local map = function(key, fn)
						vim.keymap.set('n', key, fn, { buf = conflict.bufnr })
					end

					map('co', function()
						conflict:choose_ours()
					end)
					map('ct', function()
						conflict:choose_theirs()
					end)
					map('cb', function()
						conflict:choose_both()
					end)
					map('cn', function()
						conflict:choose_none()
					end)
				end,
			}
		end,
	},
	{ src = 'https://github.com/MunifTanjim/nui.nvim' },
}
local function jj_root()
	local path = vim.api.nvim_buf_get_name(0)
	return vim.fs.root(path ~= '' and path or vim.fn.getcwd(), '.jj')
end

local function git_default_branch()
	local result = vim
		.system({ 'git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' }, {
			text = true,
		})
		:wait()

	if result.code == 0 then
		return vim.trim(result.stdout)
	end
end

vim.api.nvim_create_user_command('Review', function(opts)
	if #opts.fargs > 2 then
		vim.notify('Usage: Review [base] [target]', vim.log.levels.ERROR)
		return
	end

	local base = opts.fargs[1] or vim.env.NVIM_REVIEW_BASE
	local target = opts.fargs[2] or vim.env.NVIM_REVIEW_TARGET
	vim.env.NVIM_REVIEW_BASE = nil
	vim.env.NVIM_REVIEW_TARGET = nil

	if jj_root() then
		base = base or 'trunk()'
		target = target or '@'
		require('jj-fugitive.diff').show { rev = ('%s..%s'):format(base, target) }
		return
	end

	base = base or git_default_branch()
	if not base then
		vim.notify(
			'origin/HEAD is not configured; pass a base to :Review',
			vim.log.levels.ERROR
		)
		return
	end

	target = target or 'HEAD'
	vim.api.nvim_cmd(
		{ cmd = 'Diff', args = { 'review', ('%s...%s'):format(base, target) } },
		{}
	)
end, {
	nargs = '*',
	desc = 'Review a jj or Git branch diff',
})
