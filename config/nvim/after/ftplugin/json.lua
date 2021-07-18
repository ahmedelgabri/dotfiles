if vim.fn.executable 'jq' == 1 then
  vim.cmd [[setlocal formatprg=jq\ .]]
else
  vim.cmd [[setlocal formatprg=python\ -m\ json.tool]]
end
