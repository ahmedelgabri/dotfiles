local autopais_loaded = pcall(function()
  require('nvim-autopairs').setup {
    close_triple_quotes = true,
    check_ts = true,
    disable_filetype = { 'TelescopePrompt', 'fzf' },
  }
end)

if not autopais_loaded then
  print 'nvim-autopairs failed to load'
end
