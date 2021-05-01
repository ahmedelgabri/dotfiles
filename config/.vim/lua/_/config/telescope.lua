local actions = require("telescope.actions")
local utils = require "_.utils"
local map_opts = {noremap = true, silent = true}
local M = {}

function M.find_files()
  require "telescope.builtin".find_files {
    hidden = true,
    follow = true,
    find_command = {"fd", "--hidden", "--follow", "--no-ignore-vcs", "-t", "f"},
    prompt_prefix = string.format(
      "%s/",
      vim.fn.fnamemodify(vim.loop.cwd(), ":~")
    )
  }
end

function M.setup()
  require "telescope".setup {
    extensions = {
      fzf = {
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case"
      }
    },
    defaults = {
      selection_caret = "▶ ",
      -- winblend = 30,
      layout_strategy = "flex",
      layout_defaults = {
        horizontal = {
          preview_width = 0.6
        },
        vertical = {
          mirror = true
        }
      },
      mappings = {
        i = {
          ["<esc>"] = actions.close
        }
      },
      prompt_position = "top",
      sorting_strategy = "ascending",
      generic_sorter = require "telescope.sorters".get_fzy_sorter,
      file_sorter = require "telescope.sorters".get_fzy_sorter
    }
  }

  require "telescope".load_extension("fzf")

  utils.gmap(
    "n",
    "<leader><leader>",
    [[<cmd>lua require "_.config.telescope".find_files()<cr>]],
    map_opts
  )

  utils.gmap(
    "n",
    "<leader>b",
    [[<cmd>lua require "telescope.builtin".buffers { sort_lastused = true }<cr>]],
    map_opts
  )

  utils.gmap(
    "n",
    "<leader>h",
    [[<cmd>lua require "telescope.builtin".help_tags { show_version = true }<cr>]],
    map_opts
  )

  utils.gmap(
    "n",
    "z=",
    [[<cmd>lua require "telescope.builtin".spell_suggest {}<cr>]],
    map_opts
  )
end

return M
