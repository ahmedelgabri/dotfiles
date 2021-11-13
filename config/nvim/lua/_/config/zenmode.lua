return function()
  require('zen-mode').setup {
    on_close = function()
      local is_last_buffer = #vim.fn.filter(
        vim.fn.range(1, vim.fn.bufnr '$'),
        'buflisted(v:val)'
      ) == 1

      if vim.api.nvim_buf_get_var(0, 'quitting') == 1 and is_last_buffer then
        if vim.api.nvim_buf_get_var(0, 'quitting_bang') == 1 then
          vim.cmd 'qa!'
        else
          vim.cmd 'qa'
        end
      end
    end,

    on_open = function()
      vim.api.nvim_buf_set_var(0, 'quitting', 0)
      vim.api.nvim_buf_set_var(0, 'quitting_bang', 0)
      vim.cmd [[autocmd! QuitPre <buffer> let b:quitting = 1]]
      vim.cmd 'cabbrev <buffer> q! let b:quitting_bang = 1 <bar> q!'
    end,

    plugins = {
      options = {
        showbreak = '',
        showmode = false,
      },
      tmux = {
        enabled = true,
      },
    },
    window = {
      options = {
        cursorline = false,
        number = false,
        relativenumber = false,
      },
    },
  }
end
