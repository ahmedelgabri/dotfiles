-- fzf-lua: fuzzy finder
local actions = require 'fzf-lua.actions'
local defaults = require 'fzf-lua.defaults'
local utils = require '_.utils'

vim.g.fzf_history_dir = vim.fn.expand '~/.fzf-history'

local function log_cmd(fallback, extra)
	return vim.env.VIM_FZF_LOG
			and 'git log ' .. vim.env.VIM_FZF_LOG .. ' ' .. (extra or '')
		or fallback
end

require('fzf-lua').setup {
	defaults = {
		-- Git icons are very slow in large codea bases and not very useful
		-- https://github.com/ibhagwan/fzf-lua/wiki#how-do-i-get-maximum-performance-out-of-fzf-lua
		git_icons = false,
	},
	file_icon_padding = ' ',
	file_icons = 'mini',
	winopts = {
		border = utils.get_border(),
		preview = {
			border = utils.get_border(),
			winopts = {
				number = false,
				cursorline = true,
			},
		},
		on_create = function()
			-- disable indent plugins
			vim.b.miniindentscope_disable = true
			vim.b.snacks_indent = true
		end,
	},
	fzf_opts = {
		['--pointer'] = '▶',
		['--marker'] = '✓ ',
		['--no-scrollbar'] = true,
		['--info'] = 'inline-right',
		['--walker-skip'] = '.git,node_modules',
	},
	keymap = {
		builtin = {
			['?'] = 'toggle-preview',
		},
	},
	oldfiles = {
		include_current_session = true,
		stat_file = true,
	},
	buffers = {
		_fzf_nth_devicons = true,
	},
	files = {
		cwd_prompt = false,
		fd_opts = vim.env.FZF_DEFAULT_COMMAND and nil
			or defaults.defaults.files.fd_opts,
		cmd = vim.env.FZF_DEFAULT_COMMAND ~= nil and vim.env.FZF_DEFAULT_COMMAND
			or defaults.defaults.files.cmd,
		no_ignore = true,
		hidden = true,
		follow = true,
		line_query = true,
		_fzf_nth_devicons = true,
		actions = {
			['ctrl-g'] = false,
			['default'] = actions.file_edit,
		},
	},
	grep = {
		rg_glob = true,
		actions = {
			['ctrl-q'] = {
				fn = actions.file_edit_or_qf,
				prefix = 'select-all+',
			},
		},
	},
	commits = {
		cmd = log_cmd(defaults.defaults.git.commits.cmd),
	},
	bcommits = {
		cmd = log_cmd(defaults.defaults.git.bcommits.cmd, '{file}'),
	},
}

require('fzf-lua').register_ui_select(function(_, items)
	local min_h, max_h = 0.15, 0.70
	local h = (#items + 4) / vim.o.lines
	if h < min_h then
		h = min_h
	elseif h > max_h then
		h = max_h
	end
	return { winopts = { height = h, width = 0.60, row = 0.40 } }
end)

vim.keymap.set('n', '<leader><leader>', function()
	require('fzf-lua').files {}
end, { silent = true, desc = 'Search Files' })

vim.keymap.set('n', '<leader>b', function()
	require('fzf-lua').buffers {}
end, { silent = true, desc = 'Search [B]uffers' })

vim.keymap.set('n', '<leader>h', function()
	require('fzf-lua').help_tags {}
end, { silent = true, desc = 'Search [H]elp' })

vim.keymap.set('n', '<Leader>o', function()
	require('fzf-lua').oldfiles {}
end, { silent = true, desc = 'Search [O]ldfiles' })

vim.keymap.set('n', '<Leader>\\', function()
	require('fzf-lua').live_grep { exec_empty_query = true }
end, { silent = true, desc = 'grep project' })

vim.keymap.set('n', '<leader>ta', function()
	require('fzf-lua').grep_project {
		winopts = { title = ' Tasks ' },
		search = '^\\s*- \\[ \\]',
		no_esc = true,
		no_ignore = true,
		hidden = true,
	}
end, { desc = 'Search for incomplete t[a]sks' })

vim.keymap.set('n', '<leader>to', function()
	require('fzf-lua').grep_project {
		winopts = { title = ' TODOs ' },
		search = [[^\s*?(//|#|--|%|;|/\*)\s*@?(todo|note|hack|bug|fixme|fix|warn|xxx):?\b]],
		no_esc = true,
		no_ignore = true,
		hidden = true,
	}
end, { desc = 'Search for t[o]dos' })

vim.keymap.set('n', 'z=', function()
	require('fzf-lua').spell_suggest {}
end, { silent = true, desc = 'Spelling Suggestions' })
