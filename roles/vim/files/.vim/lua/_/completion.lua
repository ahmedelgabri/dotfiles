local utils = require'_.utils'

local M = {}

M.setup = function()
  vim.g.completion_enable_snippet = 'vim-vsnip'
  vim.g.completion_auto_change_source = 1 -- Change the completion source automatically if no completion availabe
  vim.g.completion_matching_ignore_case = 1
  vim.g.completion_trigger_on_delete = 0
  vim.g.completion_enable_auto_hover = 0
  vim.g.completion_enable_auto_signature = 0
  vim.g.completion_chain_complete_list = {
    default = {
      default = {
        {complete_items = {'lsp', 'snippet'}},
        {complete_items = {'buffers'}},
        {mode = '<c-p>'},
        {mode = '<c-n>'},
        {mode = 'dict'}
      },
      string = {
        {
          complete_items = {'path'},
          triggered_only = {'/'}
        }
      }
    }
  }

  vim.o.completeopt = 'menuone,noinsert'
  vim.o.shortmess = vim.o.shortmess .. 'c'

  utils.gmap('i', '<Tab>', [[pumvisible() ? "\<C-n>" : vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "\<Tab>"]], { expr = true })
  utils.gmap('s', '<Tab>', [[pumvisible() ? "\<C-n>" : vsnip#jumpable(1) ? "<Plug>(vsnip-jump-next)" : "\<Tab>"]], { expr = true })
  utils.gmap('i', '<S-Tab>', [[pumvisible() ? "\<C-p>" : vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "\<S-Tab>"]], { expr = true })
  utils.gmap('s', '<S-Tab>', [[pumvisible() ? "\<C-p>" : vsnip#jumpable(-1) ? "<Plug>(vsnip-jump-prev)" : "\<S-Tab>"]], { expr = true })

  utils.gmap('i', '<c-p>', 'completion#trigger_completion()', { expr = true, noremap = true, silent = true })
  utils.gmap('i', '<localleader>j', '<Plug>(completion_next_source)', {})
  utils.gmap('i', '<localleader>k', '<Plug>(completion_prev_source)', {})
end

return M
