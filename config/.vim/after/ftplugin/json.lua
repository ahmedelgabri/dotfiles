if vim.fn.executable("jq") == 1 then
  vim.opt_local.formatprg = "jq ."
else
  vim.opt_local.formatprg = "python -m json.tool"
end
