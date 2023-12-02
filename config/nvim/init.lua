-- vim: foldmethod=marker

-- Enable the Lua loader byte-compilation cache.
if vim.loader then
	vim.loader.enable()
end

-------------------------------------------------------------------------------
-- GENERAL {{{1
-------------------------------------------------------------------------------

require '_'

local au = require '_.utils.au'

local root = vim.env.USER == 'root'

vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Skip vim plugins menu.vim, saves ~100ms, disabled by lazy.nvim in plugin_manager.lua
vim.g.did_install_default_menus = 1
-- vim.g.loaded_getscript = 1
-- vim.g.loaded_getscriptPlugin = 1
-- vim.g.loaded_vimball = 1
-- vim.g.loaded_vimballPlugin = 1
-- vim.g.loaded_rrhelper = 1

-- vim.opt. them directly if they are installed, otherwise disable them. To avoid the then
-- runtime check cost, which can be slow.
-- Python This must be here becasue it makes loading vim VERY SLOW otherwise
vim.g.python_host_skip_check = 1
-- Disable python2 provider
vim.g.loaded_python_provider = 0

vim.g.python3_host_skip_check = 1

if vim.fn.executable 'python3' == 1 then
	vim.g.python3_host_prog = vim.fn.exepath 'python3'
else
	vim.g.loaded_python3_provider = 0
end

if vim.fn.executable 'neovim-node-host' == 1 then
	vim.g.node_host_prog = vim.fn.exepath 'neovim-node-host'
else
	vim.g.loaded_node_provider = 0
end

if vim.fn.executable 'neovim-ruby-host' == 1 then
	vim.g.ruby_host_prog = vim.fn.exepath 'neovim-ruby-host'
else
	vim.g.loaded_ruby_provider = 0
end

vim.g.loaded_perl_provider = 0

-------------------------------------------------------------------------------
-- OPTIONS {{{1
-------------------------------------------------------------------------------

-- use guifg/guibg instead of ctermfg/ctermbg in terminal
vim.opt.termguicolors = true
-- spaces per tab
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
-- spaces per tab (when shifting)
vim.opt.shiftwidth = 2
-- always use tabs
vim.opt.expandtab = false

vim.opt.signcolumn = 'yes'

vim.opt.cmdheight = 0

vim.opt.emoji = false

-- start highlighting from 256 lines backwards
vim.cmd 'syntax sync minlines=256'
-- do not highlight very long lines
vim.opt.synmaxcol = 300

-- Don't Display the mode you're in. since it's already shown on the statusline
vim.opt.showmode = false

-- show a navigable menu for tab completion
vim.opt.wildmode = 'longest:full,list,full'
vim.opt.wildignore:append '*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem,*.pyc'
vim.opt.wildignore:append '*.swp,*~,*/.DS_Store'

vim.opt.tagcase = 'followscs'
vim.opt.tags:prepend './.git/tags;'

-- Messes up with icons https://github.com/onsails/lspkind.nvim/issues/55
-- vim.opt.pumblend = 5
vim.opt.pumheight = 50

-- https://robots.thoughtbot.com/opt-in-project-specific-vim-spell-checking-and-word-completion
vim.opt.spelllang = 'en,nl'
vim.opt.spellsuggest = '30'
vim.opt.spellfile =
	string.format('%s%s', vim.fn.stdpath 'config', '/spell/spell.add')

vim.opt.complete:append 'kspell'

-- Disable unsafe commands. Only run autocommands owned by me http://andrew.stwrt.ca/posts/project-specific-vimrc/
vim.opt.secure = true

-- allow cursor to move where there is no text in visual block mode
vim.opt.virtualedit = 'block'

-- allow <BS>/h/l/<Left>/<Right>/<Space>, ~ to cross line boundaries
vim.opt.whichwrap = 'b,h,l,s,<,>,[,],~'

vim.opt.completeopt = 'menu,menuone,noselect'

-- don't bother updating screen during macro playback
vim.opt.lazyredraw = true

-- highlight matching [{()}]
vim.opt.showmatch = true

vim.opt.title = true
vim.opt.mouse = 'a'

-- More natural splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Ignore case in search.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- fix slight delay after pressing ESC then O http://ksjoberg.com/vim-esckeys.html
-- vim.opt.timeout timeoutlen=500 ttimeoutlen=100
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0

vim.opt.formatoptions:append 'n'
vim.opt.formatoptions:append 'r1'

-- No beeping.
vim.opt.visualbell = false

-- No flashing.
vim.opt.errorbells = false

-- Start scrolling slightly before the cursor reaches an edge
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5

-- Scroll sideways a character at a time, rather than a screen at a time
vim.opt.sidescroll = 3

-- yank and paste with the system clipboard
vim.opt.clipboard = 'unnamed'

-- show trailing whitespace
vim.opt.list = true
vim.opt.listchars = {
	multispace = '⋅ ',
	lead = '⋅',
	tab = '  ',
	-- tab = '| ',
	nbsp = '░',
	extends = '»',
	precedes = '«',
	trail = '␣',
}

if not vim.fn.has 'nvim-0.6' then
	vim.opt.joinspaces = false
end

vim.opt.concealcursor = 'n'

vim.opt.fillchars = {
	diff = '⣿', -- BOX DRAWINGS
	vert = '┃', -- HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
	fold = '─',
	msgsep = '‾',
	eob = ' ', -- Hide end of buffer ~
	foldopen = '▾',
	foldsep = '│',
	foldclose = '▸',
}

vim.opt.foldlevelstart = 99 -- start unfolded

vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

vim.opt.linebreak = true
vim.opt.textwidth = 80
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.breakindentopt = 'sbr,shift:' .. vim.bo.shiftwidth
vim.opt.showbreak = '↳  ' -- DOWNWARDS ARROW WITH TIP RIGHTWARDS (U+21B3, UTF-8: E2 86 B3)

-- show where you are
vim.opt.ruler = true

if not vim.fn.has 'nvim-0.6' then
	vim.opt.hidden = true
end

-- Make tilde command behave like an operator.
vim.opt.tildeop = true

-- Make sure diffs are always opened in vertical splits, also match my git settings
vim.opt.diffopt:append 'vertical,algorithm:histogram,indent-heuristic,hiddenoff'

if vim.fn.has 'nvim-0.9' > 0 then
	vim.opt.diffopt:append 'linematch:60'
end

vim.opt.shortmess:append 'A'
vim.opt.shortmess:append 'I'
vim.opt.shortmess:append 'O'
vim.opt.shortmess:append 'T'
vim.opt.shortmess:append 'W'
vim.opt.shortmess:append 'a'
vim.opt.shortmess:append 'o'
vim.opt.shortmess:append 't'

vim.opt.viewoptions = 'cursor,folds' -- save/restore just these (with `:{mk,load}view`)

vim.opt.backupcopy = 'yes' -- overwrite files to update, instead of renaming + rewriting
vim.opt.backup = false
vim.opt.writebackup = false

if not vim.fn.has 'nvim-0.6' then
	vim.opt.backupdir =
		string.format('%s,%s%s', '.', vim.fn.stdpath 'state', '/backup//') -- keep backup files out of the way
end

vim.opt.swapfile = false
vim.opt.directory = string.format('%s%s', vim.fn.stdpath 'state', '/swap//') -- keep swap files out of the way
vim.opt.directory:append '.'

vim.opt.updatetime = 1000
vim.opt.updatecount = 0 -- update swapfiles every 80 typed chars (I don't use swap files anymore)

if root then
	vim.opt.undofile = false -- don't create root-owned files
else
	vim.opt.undofile = true -- actually use undo files
	vim.opt.undodir:append '.'
end

if root then -- don't create root-owned files then
	vim.opt.shada = ''
	vim.opt.shadafile = 'NONE'
else
	-- Defaults:
	--   Neovim: !,'100,<50,s10,h
	-- - ! save/restore global variables (only all-uppercase variables)
	-- - '100 save/restore marks from last 100 files
	-- - <50 save/restore 50 lines from each register
	-- - s10 max item size 10KB
	-- - h do not save/restore 'hlsearch' setting
	au.augroup('MyNeovimShada', {
		{
			event = { 'CursorHold', 'FocusGained', 'FocusLost' },
			pattern = '*',
			command = [[if &bt == '' | rshada|wshada | endif]],
		},
	})
end

if not vim.fn.has 'nvim-0.6' then
	vim.opt.inccommand = 'nosplit' -- incremental command live feedback"
end

-- cursor behavior:
--   - no blinking in normal/visual mode
--   - blinking in insert-mode
vim.opt.guicursor:append 'n-v-c:blinkon0,i-ci:ver25-Cursor/lCursor-blinkwait30-blinkoff100-blinkon100'

-------------------------------------------------------------------------------
-- PLUGINS {{{1
-------------------------------------------------------------------------------
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

require '_.plugin_manager'

-------------------------------------------------------------------------------
-- OVERRIDES {{{1
-------------------------------------------------------------------------------

local vimrc_local = string.format(
	'%s/%s%s',
	vim.env.XDG_DATA_HOME,
	vim.fn.hostname(),
	'/nvimrc.lua'
)

if vim.fn.filereadable(vimrc_local) == 1 then
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
