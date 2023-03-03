local ensure_packer = function()
	local install_path = string.format(
		'%s/site/pack/packer/start/packer.nvim',
		vim.fn.stdpath 'data'
	)

	if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
		vim.fn.system {
			'git',
			'clone',
			'--depth',
			'1',
			'https://github.com/wbthomason/packer.nvim',
			install_path,
		}
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

-- HACK: see https://github.com/wbthomason/packer.nvim/issues/180
vim.fn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.15')

return require('packer').startup {
	function(use)
		use { 'https://github.com/wbthomason/packer.nvim' }
		use { 'https://github.com/windwp/nvim-autopairs' }
		use {
			'https://github.com/junegunn/fzf.vim',
			-- I have the bin globally, so don't build, and just grab plugin directory
			requires = { { 'https://github.com/junegunn/fzf' } },
		}
		use {
			'https://github.com/kyazdani42/nvim-tree.lua',
			config = require '_.config.nvim-tree',
		}
		use { 'https://github.com/duggiefresh/vim-easydir' }
		use {
			'https://github.com/ojroques/vim-oscyank',
			event = { 'TextYankPost *' },
			config = function()
				local au = require '_.utils.au'

				au.augroup('__oscyank__', {
					{
						event = { 'TextYankPost' },
						pattern = '*',
						command = [[if v:event.operator is 'y' && v:event.regname is '' | OSCYankReg " | endif]],
					},
				})
			end,
		}
		use {
			'https://github.com/junegunn/vim-peekaboo',
			event = 'BufReadPre',
			config = function()
				vim.g.peekaboo_window = 'vertical botright 60new'
			end,
		}
		use {
			'https://github.com/mbbill/undotree',
			cmd = 'UndotreeToggle',
			config = require '_.config.undotree',
		}
		use {
			'https://github.com/mhinz/vim-startify',
			event = 'BufEnter',
			config = require '_.config.startify',
		}
		use {
			'https://github.com/tpope/tpope-vim-abolish',
			cmd = { 'Abolish', 'S', 'Subvert' },
		}
		use { 'https://github.com/tpope/vim-eunuch' }
		use { 'https://github.com/tpope/vim-repeat' }
		use { 'https://github.com/machakann/vim-sandwich' }
		use {
			'https://github.com/nullchilly/fsread.nvim',
			cmd = { 'FSRead', 'FSToggle', 'FSClear' },
		}
		use {
			'https://github.com/numToStr/Comment.nvim',
			requires = {
				'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
			},
			keys = { 'gc', 'gb' },
			config = require '_.config.comment',
		}
		use { 'https://github.com/wincent/loupe' }
		use {
			'https://github.com/ojroques/nvim-bufdel',
			cmd = 'BufDel',
			setup = function()
				vim.keymap.set({ 'n' }, '<M-d>', ':BufDel!<CR>')
			end,
			config = function()
				require('bufdel').setup {
					quit = false,
				}
			end,
		}
		use {
			'https://github.com/simrat39/symbols-outline.nvim',
			cmd = 'SymbolsOutline',
		}
		use {
			'https://github.com/christoomey/vim-tmux-navigator',
			opt = true,
			cond = function()
				return vim.env.TMUX ~= nil
			end,
			config = function()
				if vim.fn.exists 'g:loaded_tmux_navigator' == 0 then
					vim.g.tmux_navigator_disable_when_zoomed = 1
				end
			end,
		}
		use { 'https://github.com/kevinhwang91/nvim-bqf' }
		use { 'https://github.com/stevearc/dressing.nvim' }
		use {
			'https://github.com/rgroli/other.nvim',
			config = require '_.config.other',
		}
		-- LSP/Autocompletion {{{
		use {
			'https://github.com/neovim/nvim-lspconfig',
			requires = {
				{
					'https://github.com/j-hui/fidget.nvim',
					config = function()
						require('fidget').setup {
							window = {
								relative = 'editor', -- where to anchor the window, either `"win"` or `"editor"`
								blend = 0, -- `&winblend` for the window
							},
							text = {
								spinner = 'dots',
							},
						}
					end,
				},
				{
					'https://github.com/jose-elias-alvarez/null-ls.nvim',
					requires = {
						'https://github.com/nvim-lua/plenary.nvim',
					},
				},
				{
					'https://github.com/folke/todo-comments.nvim',
					cmd = { 'Todocomment' },
					config = function()
						require('todo-comments').setup {}
					end,
				},
				{
					'https://github.com/folke/trouble.nvim',
					cmd = { 'Trouble' },
					config = function()
						require('trouble').setup { icons = false }
					end,
				},
				{
					'https://github.com/folke/neodev.nvim',
					config = function()
						require('neodev').setup {}
					end,
				},
				{ 'https://github.com/mickael-menu/zk-nvim' },
				{
					'https://github.com/danymat/neogen',
					cmd = { 'Neogen' },
					config = function()
						require('neogen').setup { snippet_engine = 'luasnip' }
					end,
				},
				{
					'https://github.com/b0o/SchemaStore.nvim',
				},
				{
					'https://github.com/DNLHC/glance.nvim',
					config = function()
						require('glance').setup {}
					end,
				},
			},
		}
		use {
			'https://github.com/mhartington/formatter.nvim',
			config = require '_.config.formatter',
		}
		use {
			'https://github.com/L3MON4D3/LuaSnip',
			requires = {
				{ 'https://github.com/rafamadriz/friendly-snippets' },
			},
		}
		use {
			'https://github.com/hrsh7th/nvim-cmp',
			config = require '_.config.completion',
			requires = {
				{ 'https://github.com/hrsh7th/cmp-nvim-lsp' },
				{ 'https://github.com/andersevenrud/cmp-tmux' },
				{ 'https://github.com/saadparwaiz1/cmp_luasnip' },
				{ 'https://github.com/hrsh7th/cmp-path' },
				{ 'https://github.com/hrsh7th/cmp-buffer' },
				{ 'https://github.com/hrsh7th/cmp-emoji' },
				{ 'https://github.com/f3fora/cmp-spell' },
				{ 'https://github.com/hrsh7th/cmp-cmdline' },
				{ 'https://github.com/hrsh7th/cmp-calc' },
				{ 'https://github.com/hrsh7th/cmp-nvim-lsp-signature-help' },
			},
		}
		use {
			'https://github.com/nvim-treesitter/nvim-treesitter',
			run = ':TSUpdate',
			config = require '_.config.treesitter',
			requires = {
				{ 'https://github.com/windwp/nvim-ts-autotag' },
				{
					'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
					after = 'nvim-treesitter',
				},
				{
					'https://github.com/nvim-treesitter/playground',
					cmd = 'TSPlaygroundToggle',
					after = 'nvim-treesitter',
				},
			},
		}
		-- Syntax {{{
		use {
			'https://github.com/NvChad/nvim-colorizer.lua',
			config = function()
				-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
				require('colorizer').setup {
					filetypes = {
						'*',
						'!vim',
						'!packer',
					},
					user_default_options = {
						tailwind = 'lsp',
						css = true,
					},
				}
			end,
		}
		use { 'https://github.com/jez/vim-github-hub' }
		use {
			'https://github.com/jxnblk/vim-mdx-js',
			ft = { 'mdx', 'markdown.mdx' },
		}
		-- }}}

		-- Git {{{
		use {
			'https://github.com/akinsho/git-conflict.nvim',
			config = function()
				require('git-conflict').setup {}
			end,
		}
		use {
			'https://github.com/sindrets/diffview.nvim',
			requires = { { 'https://github.com/nvim-lua/plenary.nvim' } },
			cmd = { 'DiffviewOpen' },
			config = function()
				require('diffview').setup {
					use_icons = false,
				}
			end,
		}
		use {
			'https://github.com/tpope/vim-fugitive',
			requires = {
				{ 'https://github.com/tpope/vim-rhubarb' },
			},
		}
		-- }}}

		use {
			'https://github.com/folke/zen-mode.nvim',
			config = require '_.config.zenmode',
		}

		use {
			'https://github.com/phaazon/mind.nvim',
			requires = { { 'https://github.com/nvim-lua/plenary.nvim' } },
			config = function()
				require('mind').setup {}
			end,
		}

		-- Themes, UI & eye candy {{{
		use {
			'https://github.com/ahmedelgabri/vim-colors-plain',
			-- Disable on my personal machine, use the local fork instead
			disable = vim.fn.hostname() == 'pandoras-box',
			opt = true,
		}
		use {
			vim.env.HOME .. '/Sites/personal/forks/vim-colors-plain',
			-- Disable on my work machine, use the git repo instead
			disable = vim.fn.hostname() ~= 'pandoras-box',
			opt = true,
			as = 'plain-lua',
		}
		-- }}}

		if packer_bootstrap then
			require('packer').sync()
		end
	end,
	config = {
		-- https://github.com/wbthomason/packer.nvim/issues/202
		max_jobs = 70,
		-- https://github.com/wbthomason/packer.nvim/issues/201#issuecomment-1011066526
		compile_path = vim.fn.stdpath 'data'
			.. '/site/pack/loader/start/packer.nvim/plugin/packer_compiled.lua',
		display = {
			non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
			open_cmd = function()
				return require('packer.util').float { border = 'single' }
			end,
		},
	},
}
