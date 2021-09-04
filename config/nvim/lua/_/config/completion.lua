return function()
  local utils = require '_.utils'

  local check_back_space = function()
    local col = vim.fn.col '.' - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' ~= nil
  end

  local completion_loaded = pcall(function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'

    cmp.setup {
      completion = {
        completeopt = 'menu,menuone,noinsert',
      },
      sources = {
        { name = 'buffer' },
        { name = 'nvim_lsp' },
        { name = 'tmux' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'conjure' },
        { name = 'emoji' },
        { name = 'spell' },
        { name = 'orgmode' },
        { name = 'tags' },
      },
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        -- @TODO: fix conflict with lspsaga
        -- ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        -- ['<C-e>'] = cmp.mapping.close(),
        ['<C-e>'] = cmp.mapping(function(fallback)
          if cmp.abort() then
            return
          elseif luasnip.choice_active() then
            vim.fn.feedkeys(utils.t '<Plug>luasnip-next-choice', '')
          else
            fallback()
          end
        end, {
          'i',
          's',
        }),
        ['<CR>'] = cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        },
        ['<Tab>'] = cmp.mapping(function(fallback)
          if vim.fn.pumvisible() == 1 then
            vim.fn.feedkeys(utils.t '<C-n>', 'n')
          elseif luasnip.expand_or_jumpable() then
            vim.fn.feedkeys(utils.t '<Plug>luasnip-expand-or-jump', '')
          elseif check_back_space() then
            vim.fn.feedkeys(utils.t '<Tab>', 'n')
          else
            fallback()
          end
        end, {
          'i',
          's',
        }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if vim.fn.pumvisible() == 1 then
            vim.fn.feedkeys(utils.t '<C-p>', 'n')
          elseif luasnip.jumpable(-1) then
            vim.fn.feedkeys(utils.t '<Plug>luasnip-jump-prev', '')
          else
            fallback()
          end
        end, {
          'i',
          's',
        }),
      },
    }
  end)

  if not completion_loaded then
    utils.notify 'Completion failed to set up'
  end

  pcall(function()
    require('nvim-autopairs.completion.cmp').setup {
      map_cr = true, --  map <CR> on insert mode
      map_complete = true, -- it will auto insert `(` after select function or method item
    }
  end)
end
