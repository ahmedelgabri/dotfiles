-- vim: foldmethod=marker
--
-- On `vim.opt` vs `vim.o` etc...
-- https://github.com/neovim/neovim/issues/20107
-- :h lua-guide-options

if vim.loader ~= nil then
	vim.loader.enable() -- enable the Lua loader byte-compilation cache
end

-------------------------------------------------------------------------------
-- GENERAL {{{1
-------------------------------------------------------------------------------

-- selene: allow(global_usage)
_G.__ = {} -- global namespace for helpers called from vimscript expressions

local utils = require '_.utils'

local root = vim.env.USER == 'root'

vim.g.mapleader = ' ' -- use space as the leader key
vim.g.maplocalleader = ',' -- use comma as the local leader key

vim.g.did_install_default_menus = 1 -- skip loading menu.vim to speed up startup

-- Disable unused providers to skip slow runtime availability checks at startup.
vim.g.python_host_skip_check = 1 -- skip Python 2 provider availability check
vim.g.loaded_python_provider = 0 -- disable Python 2 provider
vim.g.python3_host_skip_check = 1 -- skip Python 3 provider availability check
vim.g.loaded_python3_provider = 0 -- disable Python 3 provider
vim.g.loaded_node_provider = 0 -- disable Node.js provider
vim.g.loaded_ruby_provider = 0 -- disable Ruby provider
vim.g.loaded_perl_provider = 0 -- disable Perl provider

-------------------------------------------------------------------------------
-- OPTIONS {{{1
-------------------------------------------------------------------------------

vim.o.termguicolors = true -- use 24-bit RGB colors in the terminal
vim.o.tabstop = 2 -- visual width of a tab character
vim.o.softtabstop = 2 -- spaces inserted/removed when pressing <Tab>/<BS>
vim.o.shiftwidth = 0 -- indent width for autoindent (0 = follow tabstop)
vim.o.expandtab = false -- use real tab characters instead of spaces

vim.o.signcolumn = 'yes' -- always show the sign column to avoid layout shifts

vim.o.wildmode = 'noselect,full' -- show a navigable menu for command-line completion
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
	}, ',') -- patterns to ignore during wildcard/file expansion

vim.o.tagcase = 'followscs' -- tag matching follows smartcase setting
vim.o.tags = utils.prepend(vim.o.tags, { './.git/tags;' }) -- look for tags in .git/tags first

-- https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
vim.o.spelllang = 'en,nl' -- spell-check English and Dutch
vim.o.spellsuggest = '30' -- show up to 30 spelling suggestions
vim.o.spelloptions = 'camel' -- treat camelCase parts as separate words
vim.o.spellfile =
	string.format('%s%s', vim.fn.stdpath 'config', '/spell/spell.add') -- file `zg` writes added words to

vim.o.complete = utils.append(vim.o.complete, { 'kspell' }) -- include spell dictionary in keyword completion sources
vim.o.completeopt = 'menu,menuone,noselect,fuzzy,preinsert,nearest' -- completion popup behaviour

vim.o.virtualedit = 'block' -- allow cursor past EOL in visual block mode

vim.o.whichwrap = 'b,h,l,s,<,>,[,],~' -- keys allowed to cross line boundaries

vim.o.showmatch = true -- briefly jump to matching bracket when one is inserted

vim.o.title = true -- set window title to reflect the current file
vim.o.mouse = 'a' -- enable mouse support in all modes

vim.o.splitbelow = true -- horizontal splits open below the current window
vim.o.splitright = true -- vertical splits open to the right of the current window

vim.o.ignorecase = true -- case-insensitive search by default
vim.o.smartcase = true -- case-sensitive when search pattern contains uppercase
vim.o.infercase = true -- infer case from existing word in keyword completion
vim.o.iskeyword = utils.append(vim.o.iskeyword, { '-' }) -- treat hyphen as part of a word

vim.o.timeoutlen = 300 -- wait 300ms for a mapped key sequence to complete

vim.o.formatoptions = vim.o.formatoptions .. 'nr1' -- recognise lists, continue comments, no break before 1-letter words

vim.o.visualbell = false -- no visual bell flash
vim.o.errorbells = false -- no audible error bells

vim.o.scrolloff = 5 -- keep 5 lines visible above/below the cursor
vim.o.sidescrolloff = 5 -- keep 5 columns visible left/right of the cursor
vim.o.sidescroll = 3 -- scroll horizontally 3 columns at a time

vim.o.clipboard = 'unnamedplus' -- yank/paste use the system clipboard

vim.o.list = true -- show invisible whitespace characters
vim.o.listchars = table.concat({
	'multispace:⋅ ',
	'lead:⋅',
	'tab:  ',
	'nbsp:░',
	'extends:»',
	'precedes:«',
	'trail:␣',
}, ',') -- glyphs used to render invisible characters

vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]] -- pattern matching numbered/bulleted list items for `gw`

vim.o.joinspaces = false -- only insert one space after `.?!` when joining lines

vim.o.concealcursor = 'n' -- conceal text on the cursor line in normal mode

vim.o.fillchars = table.concat({
	'stl:⎼',
	'diff:╱',
	'msgsep:‾',
	'eob: ', -- hide end-of-buffer `~`
	'fold:─',
	'foldopen:▾',
	'foldsep: ',
	'foldclose:▸',
	'horiz:━',
	'horizup:┻',
	'horizdown:┳',
	'vert:┃',
	'vertleft:┫',
	'vertright:┣',
	'verthoriz:╋',
}, ',') -- glyphs used for window/fold/diff borders and separators

vim.o.foldcolumn = '0' -- don't show the fold column gutter
vim.o.foldlevel = 99 -- start with all folds open
vim.o.foldnestmax = 20 -- maximum number of nested folds (20 is the cap)
vim.o.foldminlines = 0 -- allow folding even single-line ranges
vim.o.foldtext = '' -- use the literal first line as fold display (no custom rendering)
vim.o.foldmethod = 'expr' -- compute folds via an expression
vim.o.foldexpr = 'v:lua.__.foldexpr(v:lnum)' -- expression returning the fold level for a line

vim.o.linebreak = true -- wrap on word boundaries instead of mid-word
vim.o.textwidth = 80 -- max line width before auto-wrapping
vim.o.autoindent = true -- copy indent from the previous line on <CR>
vim.o.smartindent = true -- smart auto-indenting for C-like syntax
vim.o.wrap = false -- don't visually wrap long lines
vim.o.breakindent = true -- visually indent wrapped lines to match the original
vim.o.breakindentopt = 'list:-1' -- align wrapped list items under the item text
vim.o.showbreak = '↳  ' -- prefix shown at the start of visually wrapped lines
vim.o.hidden = true -- allow switching away from modified buffers

vim.o.tildeop = true -- make `~` behave like an operator (e.g. `~w`)

-- always open diffs in vertical splits, use git's histogram algorithm
vim.opt.diffopt:append {
	'vertical',
	'algorithm:histogram',
	'hiddenoff',
	'foldcolumn:0',
	'linematch:60',
}

vim.o.shortmess = vim.o.shortmess .. 'AIOTWaot' -- silence noisy file/message notifications

vim.o.viewoptions = 'cursor,folds' -- save/restore only cursor and folds with `:mkview`

vim.o.backupcopy = 'yes' -- write to the original file instead of rename + rewrite
vim.o.backup = false -- don't keep backup files
vim.o.writebackup = false -- don't make a backup before overwriting a file
vim.o.backupdir =
	string.format('%s,%s%s', '.', vim.fn.stdpath 'state', '/backup//') -- where backup files would live if enabled

vim.o.swapfile = false -- don't create swap files
vim.o.directory =
	string.format('%s%s,%s', vim.fn.stdpath 'state', '/swap//', '.') -- where swap files would live if enabled

vim.o.updatetime = 250 -- shorter delay before CursorHold and swap writes

if root then
	vim.o.undofile = false -- don't create root-owned undo files
else
	vim.o.undofile = true -- persist undo history across sessions
	vim.o.undodir = utils.append(vim.o.undodir, { '.' }) -- also look for undo files in the current directory
end

if root then
	vim.o.shada = '' -- don't read/write shada state when running as root
	vim.o.shadafile = 'NONE' -- and don't load any shada file either
end

vim.o.guicursor = utils.append(vim.o.guicursor, {
	'n-v-c:blinkon0',
	'i-ci:ver25-Cursor/lCursor-blinkwait30-blinkoff100-blinkon100',
}) -- no blinking in normal/visual, blinking vertical bar in insert
vim.o.cursorline = true -- highlight the line the cursor is on
vim.o.cursorlineopt = 'screenline,number' -- only highlight the screen line and the line number
vim.o.smoothscroll = true -- smooth scrolling when soft-wrapped lines exist

vim.o.tabclose = 'uselast' -- after closing a tab, focus the previously used one

vim.o.winborder = 'bold' -- default border style for floating windows
vim.o.pumborder = vim.o.winborder -- match popup-menu border to window border

vim.o.jumpoptions = 'stack,view' -- treat the jumplist like a stack and restore view

vim.o.secure = true -- disable unsafe commands in project-local vimrcs
vim.o.exrc = true -- load project-local `.nvim.lua` / `.exrc` files

-- Experimental UI2: floating cmdline and messages
vim.o.cmdheight = 0 -- hide the cmdline when not in use (UI2 floats it)
require('vim._core.ui2').enable {
	enable = true,
	msg = {
		targets = {
			[''] = 'msg',
			empty = 'cmd',
			bufwrite = 'msg',
			confirm = 'cmd',
			emsg = 'pager',
			echo = 'msg',
			echomsg = 'msg',
			echoerr = 'pager',
			completion = 'cmd',
			list_cmd = 'pager',
			lua_error = 'pager',
			lua_print = 'msg',
			progress = 'pager',
			rpc_error = 'pager',
			quickfix = 'msg',
			search_cmd = 'cmd',
			search_count = 'cmd',
			shell_cmd = 'pager',
			shell_err = 'pager',
			shell_out = 'pager',
			shell_ret = 'msg',
			undo = 'msg',
			verbose = 'pager',
			wildlist = 'cmd',
			wmsg = 'msg',
			typed_cmd = 'cmd',
		},
		cmd = {
			height = 0.5,
		},
		dialog = {
			height = 0.5,
		},
		msg = {
			height = 0.3,
			timeout = 5000,
		},
		pager = {
			height = 0.5,
		},
	},
}
-------------------------------------------------------------------------------
-- PLUGINS {{{1
-------------------------------------------------------------------------------

vim.g.markdown_recommended_style = 0 -- disable runtime's recommended markdown style (it forces tabstop=4)
vim.g.vim_markdown_frontmatter = 1 -- enable YAML frontmatter highlighting in markdown

vim.g.markdown_fenced_languages =
	{ -- enable syntax highlighting for fenced code blocks in markdown
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

-- Disable builtin plugins we don't use
for _, plugin in ipairs {
	'getscript',
	'getscriptPlugin',
	'matchit',
	'netrwPlugin',
	'rplugin',
	'rrhelper',
	'tutor',
	'vimball',
	'vimballPlugin',
} do
	vim.g['loaded_' .. plugin] = 1
end

-------------------------------------------------------------------------------
-- OVERRIDES {{{1
-------------------------------------------------------------------------------

local vimrc_local = string.format('%s/%s', vim.env.HOST_CONFIGS, 'nvimrc.lua')

if vim.uv.fs_stat(vimrc_local) then
	vim.cmd(string.format('source %s', vimrc_local))
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
