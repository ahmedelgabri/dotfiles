-- vim: foldmethod=marker
--
-- On `vim.opt` vs `vim.o` etc...
-- https://github.com/neovim/neovim/issues/20107
-- :h lua-guide-options

-- Enable the Lua loader byte-compilation cache.
if vim.loader then
	vim.loader.enable()
end

-------------------------------------------------------------------------------
-- GENERAL {{{1
-------------------------------------------------------------------------------

-- My global namespace
-- selene: allow(global_usage)
_G.__ = {}

local utils = require '_.utils'

local root = vim.env.USER == 'root'

vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Skip vim plugins menu.vim, saves ~100ms, disabled by lazy later in this file
vim.g.did_install_default_menus = 1

-- vim.o. them directly if they are installed, otherwise disable them. To avoid the then
-- runtime check cost, which can be slow.
-- Python This must be here because it makes loading vim VERY SLOW otherwise
vim.g.python_host_skip_check = 1
vim.g.loaded_python_provider = 0

vim.g.python3_host_skip_check = 1
vim.g.loaded_python3_provider = 0

vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-------------------------------------------------------------------------------
-- OPTIONS {{{1
-------------------------------------------------------------------------------

-- use guifg/guibg instead of ctermfg/ctermbg in terminal
vim.o.termguicolors = true
-- spaces per tab
vim.o.tabstop = 2
vim.o.softtabstop = 2
-- spaces per tab (when shifting), Zero means use tabstop value
vim.o.shiftwidth = 0
-- always use tabs
vim.o.expandtab = false

vim.o.signcolumn = 'yes'

vim.o.emoji = false

-- start highlighting from 256 lines backwards
vim.cmd 'syntax sync minlines=256'
-- do not highlight very long lines
vim.o.synmaxcol = 300

-- Don't Display the mode you're in. since it's already shown on the statusline
vim.o.showmode = false

-- show a navigable menu for tab completion
vim.o.wildmode = 'longest:full,list,full'
vim.o.wildignore = vim.o.wildignore
	.. table.concat({
		'*.o',
		'*.out',
		'*.obj',
		'.git',
		'*.rbc',
		'*.rbo',
		'*.class',
		'.svn',
		'*.gem',
		'*.pyc',
		'*.swp',
		'*~',
		'*/.DS_Store',
	}, ',')

vim.o.tagcase = 'followscs'
vim.o.tags = utils.prepend('tags', { './.git/tags;' })

-- https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
vim.o.spelllang = 'en,nl'
vim.o.spellsuggest = '30'
vim.o.spellfile =
	string.format('%s%s', vim.fn.stdpath 'config', '/spell/spell.add')

vim.o.complete = utils.append('complete', { 'kspell' })

-- Disable unsafe commands. Only run autocommands owned by me http://andrew.stwrt.ca/posts/project-specific-vimrc/
vim.o.secure = true

-- allow cursor to move where there is no text in visual block mode
vim.o.virtualedit = 'block'

-- allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries
vim.o.whichwrap = 'b,h,l,s,<,>,[,],~'

vim.o.completeopt = 'menu,menuone,noselect,fuzzy,preinsert'

-- don't bother updating screen during macro playback
vim.o.lazyredraw = true

-- highlight matching [{()}]
vim.o.showmatch = true

vim.o.title = true
vim.o.mouse = 'a'

-- More natural splitting
vim.o.splitbelow = true
vim.o.splitright = true

-- Ignore case in search.
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.timeoutlen = 300

vim.o.formatoptions = vim.o.formatoptions .. 'nr1'

-- No beeping.
vim.o.visualbell = false

-- No flashing.
vim.o.errorbells = false

-- Start scrolling slightly before the cursor reaches an edge
vim.o.scrolloff = 5
vim.o.sidescrolloff = 5

-- Scroll sideways a character at a time, rather than a screen at a time
vim.o.sidescroll = 3

-- yank and paste with the system clipboard
vim.o.clipboard = 'unnamedplus'

-- show trailing whitespace
vim.o.list = true
vim.o.listchars = table.concat({
	'multispace:⋅ ',
	'lead:⋅',
	'tab:  ',
	-- 'tab:| ',
	'nbsp:░',
	'extends:»',
	'precedes:«',
	'trail:␣',
}, ',')

if not vim.fn.has 'nvim-0.6' then
	vim.o.joinspaces = false
end

vim.o.concealcursor = 'n'

vim.o.fillchars = table.concat({
	'stl:⎼',
	'diff:╱',
	'msgsep:‾',
	'eob: ', -- Hide end of buffer ~
	'fold:─',
	'foldopen:▾',
	'foldsep: ',
	'foldclose:▸',
	'horiz:━',
	'horizup:┻',
	'horizdown:┳',
	'vert:┃', -- HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
	'vertleft:┫',
	'vertright:┣',
	'verthoriz:╋',
}, ',')

vim.o.foldcolumn = '0'
vim.o.foldlevel = 99
vim.o.foldnestmax = 4
vim.o.foldlevelstart = 99 -- start unfolded
vim.o.foldminlines = 0 -- Allow closing even 1-line folds.
-- https://www.reddit.com/r/neovim/comments/1fv8o74/is_it_too_much_to_ask_for_a_foldline_that_looks/
vim.o.foldtext = ''
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.__.foldexpr(v:lnum)'
-- vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

vim.o.linebreak = true
vim.o.textwidth = 80
vim.o.wrap = false
vim.o.breakindent = true
vim.o.breakindentopt = 'sbr,shift:' .. vim.bo.shiftwidth
vim.o.showbreak = '↳  ' -- DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)

-- show where you are
vim.o.ruler = true

if not vim.fn.has 'nvim-0.6' then
	vim.o.hidden = true
end

-- Make tilde command behave like an operator.
vim.o.tildeop = true

-- Make sure diffs are always opened in vertical splits, also match my git settings
vim.o.diffopt = utils.append(
	'diffopt',
	{ 'vertical', 'algorithm:histogram', 'indent-heuristic', 'hiddenoff' }
)

if vim.fn.has 'nvim-0.9' > 0 then
	vim.o.diffopt = utils.append('diffopt', { 'linematch:60' })
end

vim.o.shortmess = vim.o.shortmess .. 'AIOTWaot'

vim.o.viewoptions = 'cursor,folds' -- save/restore just these (with `:{mk,load}view`)

vim.o.backupcopy = 'yes' -- overwrite files to update, instead of renaming + rewriting
vim.o.backup = false
vim.o.writebackup = false

if not vim.fn.has 'nvim-0.6' then
	vim.o.backupdir =
		string.format('%s,%s%s', '.', vim.fn.stdpath 'state', '/backup//') -- keep backup files out of the way
end

vim.o.swapfile = false
vim.o.directory =
	string.format('%s%s,%s', vim.fn.stdpath 'state', '/swap//', '.') -- keep swap files out of the way

vim.o.updatetime = 250

if root then
	vim.o.undofile = false -- don't create root-owned files
else
	vim.o.undofile = true -- actually use undo files
	vim.o.undodir = utils.append('undodir', { '.' })
end

-- Shada Defaults:
--   Neovim: !,'100,<50,s10,h
-- - ! save/restore global variables (only all-uppercase variables)
-- - '100 save/restore marks from last 100 files
-- - <50 save/restore 50 lines from each register
-- - s10 max item size 10KB
-- - h do not save/restore 'hlsearch' setting

if root then -- don't create root-owned files then
	vim.o.shada = ''
	vim.o.shadafile = 'NONE'
end

-- cursor behavior:
--   - no blinking in normal/visual mode
--   - blinking in insert-mode
vim.o.guicursor = utils.append('guicursor', {
	'n-v-c:blinkon0',
	'i-ci:ver25-Cursor/lCursor-blinkwait30-blinkoff100-blinkon100',
})
vim.o.smoothscroll = true

vim.o.tabclose = 'uselast'

vim.o.winborder = 'bold'
-------------------------------------------------------------------------------
-- PLUGINS {{{1
-------------------------------------------------------------------------------
-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
-- disable frontmatter highlighting
vim.g.vim_markdown_frontmatter = 1

vim.g.markdown_fenced_languages = {
	'css',
	'erb=eruby',
	'javascript',
	'js=javascript',
	'jsx=javascriptreact',
	'ts=typescript',
	'tsx=typescriptreact',
	'json=jsonc',
	'ruby',
	'sass',
	'scss=sass',
	'xml',
	'html',
	'py=python',
	'python',
	'clojure',
	'clj=clojure',
	'cljs=clojure',
	'stylus=css',
	'less=css',
	'viml=vim',
}

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable', -- latest stable release
		lazypath,
	}
end

vim.o.rtp = utils.prepend('rtp', { lazypath })

require('lazy').setup {
	spec = {
		{ import = 'plugins' },
	},
	---@diagnostic disable-next-line: assign-type-mismatch
	dev = {
		-- directory where you store your local plugin projects
		path = '~/Sites/personal/forks',
		---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
		patterns = { 'ahmedelgabri' }, -- For example {"folke"}
		fallback = true, -- Fallback to git when local plugin doesn't exist
	},
	ui = {
		border = utils.get_border(),
		backdrop = 0,
	},
	performance = {
		rtp = {
			-- Stuff I don't use.
			disabled_plugins = {
				'getscript',
				'getscriptPlugin',
				'netrwPlugin',
				'rplugin',
				'rrhelper',
				'tohtml',
				'tutor',
				'vimball',
				'vimballPlugin',
			},
		},
	},
	-- Don't bother me when tweaking plugins.
	change_detection = { notify = false },
	profiling = {
		-- Track each new require in the Lazy profiling tab
		require = true,
	},
}

-------------------------------------------------------------------------------
-- OVERRIDES {{{1
-------------------------------------------------------------------------------

local vimrc_local = string.format(
	'%s/%s%s',
	vim.env.XDG_DATA_HOME,
	vim.fn.hostname(),
	'/nvimrc.lua'
)

if vim.uv.fs_stat(vimrc_local) then
	vim.cmd(string.format('silent source %s', vimrc_local))
end

-------------------------------------------------------------------------------
-- FOOTER {{{1
-------------------------------------------------------------------------------

--[[
After this file is sourced, plugin code will be evaluated (eg.
~/.config/nvim/plugin/* and so on ). See ~/.config/nvim/after for files
evaluated after that.  See `:scriptnames` for a list of all scripts, in
evaluation order.
Launch Neovim with `nvim --startuptime nvim.log` for profiling info.
To see all leader mappings, including those from plugins:
    nvim -c 'map <Leader>'
    nvim -c 'map <LocalLeader>'
--]]
