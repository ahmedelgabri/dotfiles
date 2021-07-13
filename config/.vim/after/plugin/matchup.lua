if vim.fn.exists(":Matchup") == 0 then
  return
end

vim.g.matchup_surround_enabled = 1
vim.g.matchup_transmute_enabled = 1
vim.g.matchup_matchpref_html_nolists = 1
vim.g.matchup_matchparen_deferred = 1
