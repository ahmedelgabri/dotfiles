local actions = require 'telescope.actions'
local map = require '_.utils.map'
local M = {}

function M.find_files()
  require('telescope.builtin').find_files {
    previewer = false,
    hidden = true,
    follow = true,
    -- results_height = 50,
    find_command = {
      'fd',
      '--hidden',
      '--follow',
      '--no-ignore-vcs',
      '-t',
      'f',
    },
    prompt_title = string.format(
      '%s/',
      vim.fn.fnamemodify(vim.loop.cwd(), ':~')
    ),
    prompt_prefix = ' ',
  }
end

function M.setup()
  require('telescope').setup {
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = false, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = 'smart_case',
      },
    },
    defaults = {
      selection_caret = '▶ ',
      -- winblend = 30,
      layout_strategy = 'flex',
      layout_config = {
        width = 0.95,
        prompt_position = 'top',
        horizontal = {
          preview_width = 0.6,
        },
        vertical = {
          mirror = true,
        },
      },
      mappings = {
        i = {
          ['<esc>'] = actions.close,
        },
      },
      sorting_strategy = 'ascending',
      generic_sorter = require('telescope.sorters').get_fzy_sorter,
      file_sorter = require('telescope.sorters').get_fzy_sorter,
    },
  }

  require('telescope').load_extension 'fzf'

  map.nnoremap(
    '<leader><leader>',
    [[<cmd>lua require "_.config.telescope".find_files()<cr>]]
  )

  map.nnoremap(
    '<leader>b',
    [[<cmd>lua require "telescope.builtin".buffers { sort_lastused = true, show_all_buffers = true }<cr>]]
  )

  map.nnoremap(
    '<leader>h',
    [[<cmd>lua require "telescope.builtin".help_tags { show_version = true }<cr>]]
  )

  map.nnoremap(
    'z=',
    [[<cmd>lua require "telescope.builtin".spell_suggest {}<cr>]]
  )
end

return M
