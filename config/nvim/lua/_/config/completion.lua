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
      view = {
        entries = 'native',
      },
      experimental = {
        ghost_text = true,
      },
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
      documentation = {
        border = 'single',
      },
      completion = {
        completeopt = 'menu,menuone,noinsert',
        get_trigger_characters = function(trigger_characters)
          return vim.tbl_filter(function(char)
            return char ~= ' '
          end, trigger_characters)
        end,
      },
      sources = cmp.config.sources {
        { name = 'luasnip' },
        { name = 'nvim_lsp' },
        { name = 'calc' },
        { name = 'path' },
        { name = 'nvim_lsp_signature_help' },
        { name = 'conjure' },
        {
          name = 'buffer',
          max_item_count = 10,
          keyword_length = 5,
          option = {
            get_bufnrs = function()
              return { vim.api.nvim_get_current_buf() }
            end,
            -- get_bufnrs = vim.api.nvim_list_bufs,
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
        { name = 'orgmode' },
        { name = 'emoji' },
        { name = 'spell' },
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
        ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
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
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        },
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
          elseif luasnip.expand_or_locally_jumpable() then
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
            cmp.select_prev_item { behavior = cmp.SelectBehavior.Select }
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
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    local cmp = require 'cmp'

    cmp.event:on(
      'confirm_done',
      cmp_autopairs.on_confirm_done { map_char = { tex = '' } }
    )

    require('nvim-autopairs').setup {
      map_cr = false,
      close_triple_quotes = true,
      check_ts = true,
      disable_filetype = { 'TelescopePrompt', 'fzf' },
    }
  end)
end
