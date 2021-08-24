-- Only required if you have packer in your `opt` pack
local packer_exists, packer = pcall(require, 'packer')

if not packer_exists then
  if vim.fn.input 'Download Packer? (y for yes) ' ~= 'y' then
    return
  end

  local directory = string.format(
    '%s/pack/packer/start/',
    vim.fn.stdpath 'config'
  )

  vim.fn.mkdir(directory, 'p')

  local out = vim.fn.system(
    string.format(
      'git clone %s %s',
      'https://github.com/wbthomason/packer.nvim',
      directory .. 'packer.nvim'
    )
  )

  print(out)
  print 'Downloading packer.nvim...'
  vim.fn.execute 'packadd packer.nvim'

  return
end

local au = require '_.utils.au'
local lisps = { 'lisp', 'scheme', 'clojure', 'fennel' }

packer.init {
  package_root = string.format('%s/pack', vim.fn.stdpath 'config'),
  display = {
    non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
    open_cmd = function()
      return require('packer.util').float { border = 'single' }
    end,
  },
}

return packer.startup(function(use)
  au.augroup('__packer__', function()
    au.autocmd('BufWritePost', 'plugins.lua', 'PackerCompile')
  end)

  use { 'https://github.com/wbthomason/packer.nvim' }
  use { 'https://github.com/antoinemadec/FixCursorHold.nvim' }
  use { 'https://github.com/windwp/nvim-autopairs' }
  use {
    'https://github.com/junegunn/fzf.vim',
    -- I have the bin globally, so don't build, and just grab plugin directory
    requires = { { 'https://github.com/junegunn/fzf' } },
  }
  use {
    'https://github.com/kyazdani42/nvim-tree.lua',
    keys = { '-' },
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
  }
  use { 'https://github.com/duggiefresh/vim-easydir' }
  use { 'https://github.com/junegunn/vim-peekaboo' }
  use {
    'https://github.com/mbbill/undotree',
    opt = true,
    cmd = 'UndotreeToggle',
  }
  use { 'https://github.com/mhinz/vim-startify' }
  use { 'https://github.com/nelstrom/vim-visual-star-search' }
  use { 'https://github.com/tpope/tpope-vim-abolish' }
  use { 'https://github.com/tpope/vim-eunuch' }
  use { 'https://github.com/tpope/vim-repeat' }
  use { 'https://github.com/machakann/vim-sandwich' }
  use { 'https://github.com/tomtom/tcomment_vim', keys = { 'gc' } }
  use { 'https://github.com/wincent/loupe' }
  use { 'https://github.com/mhinz/vim-sayonara', opt = true, cmd = 'Sayonara' }
  use {
    'https://github.com/simrat39/symbols-outline.nvim',
    cmd = 'SymbolsOutline',
  }
  use { 'https://github.com/christoomey/vim-tmux-navigator', opt = true }
  use { 'https://github.com/kevinhwang91/nvim-bqf' }
  -- LSP/Autocompletion {{{
  use {
    'https://github.com/neovim/nvim-lspconfig',
    requires = {
      { 'https://github.com/tjdevries/lsp_extensions.nvim' },
      {
        'https://github.com/folke/todo-comments.nvim',
        config = function()
          require('todo-comments').setup {}
        end,
      },
      { 'https://github.com/glepnir/lspsaga.nvim' },
      { 'https://github.com/ray-x/lsp_signature.nvim' },
    },
  }
  use { 'https://github.com/mhartington/formatter.nvim' }
  use {
    'https://github.com/L3MON4D3/LuaSnip',
    requires = {
      { 'https://github.com/rafamadriz/friendly-snippets' },
    },
  }
  use {
    'https://github.com/hrsh7th/nvim-compe',
    requires = {
      { 'https://github.com/tami5/compe-conjure', ft = lisps },
      { 'https://github.com/andersevenrud/compe-tmux' },
    },
  }
  use {
    'https://github.com/nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = {
      { 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },
      { 'https://github.com/p00f/nvim-ts-rainbow' },
      {
        'https://github.com/nvim-treesitter/playground',
        cmd = 'TSPlaygroundToggle',
      },
    },
  }
  -- Syntax {{{
  use {
    'https://github.com/norcalli/nvim-colorizer.lua',
    config = function()
      -- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
      require('colorizer').setup({
        '*',
        '!vim',
        '!packer',
      }, {
        css = true,
      })
    end,
  }
  use {
    'https://github.com/kristijanhusak/orgmode.nvim',
    config = function()
      require('orgmode').setup {
        org_agenda_files = { '~/Sync/org/*' },
        org_default_notes_file = '~/Sync/refile.org',
      }
    end,
  }
  use {
    'https://github.com/plasticboy/vim-markdown',
    ft = { 'markdown' },
    requires = {
      { 'https://github.com/godlygeek/tabular' },
      { 'https://github.com/npxbr/glow.nvim', cmd = 'Glow' },
    },
  }
  use { 'https://github.com/jez/vim-github-hub' }
  -- Clojure
  use { 'https://github.com/guns/vim-sexp', ft = lisps }
  use { 'https://github.com/Olical/conjure', tag = 'v4.23.0', ft = lisps }
  -- }}}

  -- Git {{{
  use {
    'https://github.com/rhysd/conflict-marker.vim',
    config = function()
      -- disable the default highlight group
      vim.g.conflict_marker_highlight_group = ''

      -- Include text after begin and end markers
      vim.g.conflict_marker_begin = '^<<<<<<< .*$'
      vim.g.conflict_marker_end = '^>>>>>>> .*$'
    end,
  }
  use {
    'https://github.com/sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen' },
    config = function()
      require('diffview').setup {
        file_panel = {
          use_icons = false,
        },
      }
    end,
  }
  use {
    'https://github.com/tpope/vim-fugitive',
    requires = {
      { 'https://github.com/tpope/vim-rhubarb' },
    },
  }
  use {
    'https://github.com/rhysd/git-messenger.vim',
    opt = true,
    cmd = 'GitMessenger',
    keys = '<Plug>(git-messenger)',
  }
  -- }}}

  -- Themes, UI & eye cnady {{{
  use { 'https://github.com/andreypopp/vim-colors-plain', opt = true }
  use { 'https://github.com/liuchengxu/space-vim-theme', opt = true }
  use { 'https://github.com/rakr/vim-two-firewatch', opt = true }
  use { 'https://github.com/logico-dev/typewriter', opt = true }
  use { 'https://github.com/arzg/vim-substrata', opt = true }
  use { 'https://github.com/haishanh/night-owl.vim', opt = true }
  use { 'https://github.com/lifepillar/vim-gruvbox8', opt = true }
  use { 'https://github.com/bluz71/vim-moonfly-colors', opt = true }
  use { 'https://github.com/axvr/photon.vim', opt = true }
  use { 'https://github.com/owickstrom/vim-colors-paramount', opt = true }
  use { 'https://github.com/YorickPeterse/vim-paper', opt = true }
end)
