if vim.fn.exists(":Vista") == 0 then
  return
end

vim.g.vista["#renderer#enable_icon"] = 1
vim.g.vista_close_on_jump = 1
vim.g.vista_executive_for = {
  go = "nvim_lsp",
  javascript = "nvim_lsp",
  ["javascript.jsx"] = "nvim_lsp",
  typescript = "nvim_lsp",
  ["typescript.tsx"] = "nvim_lsp",
  python = "nvim_lsp"
}
