return function()
  local utils = require '_.utils'

  local has_words_before = function()
    if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
      return false
    end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0
      and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
          :sub(col, col)
          :match '%s'
        == nil
  end

  local completion_loaded = pcall(function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    local menu = {
      buffer = ' Buffer',
      nvim_lsp = ' LSP',
      luasnip = ' Snip',
      path = ' Path',
      tmux = ' Tmux',
      orgmode = ' Org',
      emoji = ' Emoji',
      spell = ' Spell',
      conjure = ' Conjure',
    }

    cmp.setup {
      formatting = {
        -- format = function(entry, vim_item)
        --   vim_item.menu = (menu)[entry.source.name]
        --   return vim_item
        -- end,
        format = require('lspkind').cmp_format {
          with_text = true,
          max_width = 100,
          menu = menu,
        },
      },
      completion = {
        completeopt = 'menu,menuone,noinsert',
        get_trigger_characters = function(trigger_characters)
          return vim.tbl_filter(function(char)
            return char ~= ' '
          end, trigger_characters)
        end,
      },
      sources = {
        { name = 'luasnip', priority = 10 },
        { name = 'nvim_lsp', priority = 9 },
        {
          name = 'buffer',
          max_item_count = 10,
          opts = {
            get_bufnrs = vim.api.nvim_list_bufs,
            -- get_bufnrs = function()
            --   local bufs = {}
            --   for _, win in ipairs(vim.api.nvim_list_wins()) do
            --     bufs[vim.api.nvim_win_get_buf(win)] = true
            --   end
            --   return vim.tbl_keys(bufs)
            -- end,
          },
        },
        { name = 'tmux', max_item_count = 10 },
        { name = 'tags' },
        { name = 'orgmode' },
        { name = 'path' },
        { name = 'conjure' },
        { name = 'emoji' },
        { name = 'spell' },
        { name = 'treesitter' },
      },
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = {
        ['<C-n>'] = cmp.mapping.select_next_item {
          behavior = cmp.SelectBehavior.Insert,
        },
        ['<C-p>'] = cmp.mapping.select_prev_item {
          behavior = cmp.SelectBehavior.Insert,
        },
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        -- ['<C-e>'] = cmp.mapping.close(),
        ['<C-e>'] = cmp.mapping(function(fallback)
          if cmp.abort() then
            return
          elseif luasnip.choice_active() then
            luasnip.jump(1)
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
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, {
          'i',
          's',
        }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
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
