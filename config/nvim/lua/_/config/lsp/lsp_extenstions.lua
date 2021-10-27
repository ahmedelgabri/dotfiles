return function()
  local au = require '_.utils.au'

  au.augroup('__COMPLETION__', function()
    au.autocmd(
      'CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost',
      '*.rs',
      "lua require'lsp_extensions'.inlay_hints()"
    )
  end)
end
