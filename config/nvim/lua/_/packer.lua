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

  OUT = vim.fn.system(
    string.format(
      'git clone %s %s',
      'https://github.com/wbthomason/packer.nvim',
      directory .. 'packer.nvim'
    )
  )

  print(OUT)
  print 'Downloading packer.nvim...'
  vim.fn.execute 'packadd packer.nvim'

  return
end

-- HACK: see https://github.com/wbthomason/packer.nvim/issues/180
vim.fn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.15')

local lisps = { 'lisp', 'scheme', 'clojure', 'fennel' }
return packer.startup {
  config = {
    max_jobs = 70, -- https://github.com/wbthomason/packer.nvim/issues/202
    display = {
      non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
      open_cmd = function()
        return require('packer.util').float { border = 'single' }
      end,
    },
  },
  function(use)
    use { 'https://github.com/wbthomason/packer.nvim' }
    use { 'https://github.com/windwp/nvim-autopairs' }
    use {
      'https://github.com/soywod/himalaya',
      rtp = 'email-manager/vim',
    }
    use {
      'https://github.com/junegunn/fzf.vim',
      -- I have the bin globally, so don't build, and just grab plugin directory
      requires = { { 'https://github.com/junegunn/fzf' } },
    }
    use {
      'https://github.com/kyazdani42/nvim-tree.lua',
      keys = { '--' },
      cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
      config = require '_.config.nvim-tree',
    }
    use { 'https://github.com/duggiefresh/vim-easydir' }
    use {
      'https://github.com/ojroques/vim-oscyank',
      event = { 'TextYankPost *' },
      config = function()
        vim.cmd [[augroup __oscyank__]]
        vim.cmd [[autocmd!]]
        vim.cmd [[autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | OSCYankReg " | endif]]
        vim.cmd [[augroup END]]
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
    use { 'https://github.com/nelstrom/vim-visual-star-search' }
    use {
      'https://github.com/tpope/tpope-vim-abolish',
      cmd = { 'Abolish', 'S', 'Subvert' },
    }
    use { 'https://github.com/tpope/vim-eunuch' }
    use { 'https://github.com/tpope/vim-repeat' }
    use { 'https://github.com/machakann/vim-sandwich' }
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
        local map = require '_.utils.map'
        map.nnoremap('<M-d>', ':BufDel<CR>')
      end,
      config = function()
        require('bufdel').setup {
          quit = false,
        }
      end,
    }
    use { 'https://github.com/tpope/vim-apathy' }
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
    -- LSP/Autocompletion {{{
    use {
      'https://github.com/neovim/nvim-lspconfig',
      requires = {
        {
          'https://github.com/jose-elias-alvarez/null-ls.nvim',
          requires = {
            'https://github.com/nvim-lua/plenary.nvim',
          },
        },
        {
          'https://github.com/folke/todo-comments.nvim',
          config = function()
            require('todo-comments').setup {}
          end,
        },
        { 'https://github.com/folke/lua-dev.nvim' },
        { 'https://github.com/mickael-menu/zk-nvim' },
      },
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
        { 'https://github.com/onsails/lspkind-nvim' },
        { 'https://github.com/hrsh7th/cmp-nvim-lsp' },
        { 'https://github.com/andersevenrud/cmp-tmux' },
        { 'https://github.com/saadparwaiz1/cmp_luasnip' },
        { 'https://github.com/hrsh7th/cmp-path' },
        { 'https://github.com/PaterJason/cmp-conjure', ft = lisps },
        { 'https://github.com/hrsh7th/cmp-buffer' },
        { 'https://github.com/hrsh7th/cmp-emoji' },
        { 'https://github.com/f3fora/cmp-spell' },
        { 'https://github.com/hrsh7th/cmp-cmdline' },
        { 'https://github.com/hrsh7th/cmp-calc' },
      },
    }
    use {
      'https://github.com/nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate',
      config = require '_.config.treesitter',
      requires = {
        {
          'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
          after = 'nvim-treesitter',
        },
        -- {
        --   'https://github.com/p00f/nvim-ts-rainbow',
        --   after = 'nvim-treesitter',
        -- },
        {
          'https://github.com/nvim-treesitter/playground',
          cmd = 'TSPlaygroundToggle',
          after = 'nvim-treesitter',
        },
        {
          'https://github.com/kristijanhusak/orgmode.nvim',
          run = ':TSUpdate org',
          config = function()
            require('orgmode').setup {
              org_agenda_files = {
                string.format('%s/org/*', vim.env.NOTES_DIR),
              },
              org_default_notes_file = string.format(
                '%s/org/refile.org',
                vim.env.NOTES_DIR
              ),
              mappings = {
                agenda = {
                  org_agenda_later = '>',
                  org_agenda_earlier = '<',
                },
                capture = {
                  org_capture_finalize = '<Leader>w',
                  org_capture_refile = 'R',
                  org_capture_kill = 'Q',
                },
                org = {
                  org_timestamp_up = '+',
                  org_timestamp_down = '-',
                },
              },
              org_hide_emphasis_markers = true,
              -- org_agenda_start_on_weekday = false,
              org_todo_keywords = {
                'TODO(t)',
                'PROGRESS(p)',
                '|',
                'DONE(d)',
                'REJECTED(r)',
              },
              org_agenda_templates = {
                T = {
                  description = 'Todo',
                  template = '* TODO %?\n  DEADLINE: %T',
                  target = string.format('%s/org/todos.org', vim.env.NOTES_DIR),
                },
                w = {
                  description = 'Work todo',
                  template = '* TODO %?\n  DEADLINE: %T',
                  target = string.format('%s/org/work.org', vim.env.NOTES_DIR),
                },
              },
              -- notifications = {
              --   reminder_time = { 0, 1, 5, 10 },
              --   repeater_reminder_time = { 0, 1, 5, 10 },
              --   deadline_warning_reminder_time = { 0 },
              --   cron_notifier = function(tasks)
              --     for _, task in ipairs(tasks) do
              --       local title = string.format(
              --         '%s (%s)',
              --         task.category,
              --         task.humanized_duration
              --       )
              --       local subtitle = string.format(
              --         '%s %s %s',
              --         string.rep('*', task.level),
              --         task.todo,
              --         task.title
              --       )
              --       local date = string.format(
              --         '%s: %s',
              --         task.type,
              --         task.time:to_string()
              --       )
              --
              --       if vim.fn.executable 'terminal-notifier' == 1 then
              --         vim.loop.spawn('terminal-notifier', {
              --           args = {
              --             '-title',
              --             title,
              --             '-subtitle',
              --             subtitle,
              --             '-message',
              --             date,
              --           },
              --         })
              --       end
              --
              --       if vim.fn.executable 'osascript' == 1 then
              --         vim.loop.spawn('osascript', {
              --           args = {
              --             '-e',
              --             string.format(
              --               "display notification '%s - %s' with title '%s'",
              --               subtitle,
              --               date,
              --               title
              --             ),
              --           },
              --         })
              --       end
              --     end
              --   end,
              -- },
            }
          end,
          requires = { { 'https://github.com/akinsho/org-bullets.nvim' } },
        },
      },
    }
    use {
      'https://github.com/vuki656/package-info.nvim',
      requires = { 'https://github.com/MunifTanjim/nui.nvim' },
      ft = { 'json' },
      config = function()
        require('package-info').setup { force = true }
      end,
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
      'https://github.com/plasticboy/vim-markdown',
      ft = { 'markdown' },
      requires = {
        { 'https://github.com/godlygeek/tabular', after = 'vim-markdown' },
        {
          'https://github.com/npxbr/glow.nvim',
          cmd = 'Glow',
          after = 'vim-markdown',
        },
      },
    }
    use { 'https://github.com/jez/vim-github-hub' }
    use { 'https://github.com/lumiliet/vim-twig', ft = { 'twig' } }
    use {
      'https://github.com/jxnblk/vim-mdx-js',
      ft = { 'mdx', 'markdown.mdx' },
    }
    -- use {
    --   'https://github.com/lukas-reineke/headlines.nvim',
    --   config = function()
    --     require('headlines').setup()
    --   end,
    -- }
    -- Clojure
    use { 'https://github.com/guns/vim-sexp', ft = lisps }
    use {
      'https://github.com/tpope/vim-sexp-mappings-for-regular-people',
      ft = lisps,
    }
    use {
      'https://github.com/Olical/conjure',
      branch = 'master',
      ft = lisps,
    }
    -- }}}

    -- Git {{{
    use {
      'https://github.com/rhysd/conflict-marker.vim',
      cmd = {
        'ConflictMarkerBoth',
        'ConflictMarkerNone',
        'ConflictMarkerOurselves',
        'ConflictMarkerThemselves',
      },
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
    use {
      'https://github.com/rhysd/git-messenger.vim',
      cmd = 'GitMessenger',
      keys = '<Plug>(git-messenger)',
    }
    -- }}}

    use {
      'https://github.com/folke/zen-mode.nvim',
      config = require '_.config.zenmode',
    }

    -- Themes, UI & eye candy {{{
    use { 'https://github.com/andreypopp/vim-colors-plain', opt = true }
    use { 'https://github.com/rakr/vim-two-firewatch', opt = true }
    use { 'https://github.com/logico-dev/typewriter', opt = true }
    use { 'https://github.com/arzg/vim-substrata', opt = true }
    use { 'https://github.com/bluz71/vim-moonfly-colors', opt = true }
    use { 'https://github.com/axvr/photon.vim', opt = true }
    use { 'https://github.com/owickstrom/vim-colors-paramount', opt = true }
    use { 'https://github.com/YorickPeterse/vim-paper', opt = true }
    -- }}}

    if OUT then
      require('packer').sync()
    end
  end,
}
