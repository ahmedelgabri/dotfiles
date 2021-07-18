local has_autopairs, autopairs = pcall(require, 'nvim-autopairs')

if not has_autopairs then
  return
end

autopairs.setup {
  close_triple_quotes = true,
  check_ts = true,
  disable_filetype = { 'TelescopePrompt', 'fzf' },
}

if not has_autopairs then
  return
end

autopairs.setup {
  close_triple_quotes = true,
  check_ts = true,
  disable_filetype = { 'TelescopePrompt', 'fzf' },
}
