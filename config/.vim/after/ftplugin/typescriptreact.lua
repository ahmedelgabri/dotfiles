-- Work around filetype that landed in upstream Vim here:
-- https://github.com/vim/vim/issues/4830
vim.fn.execute(
  string.format(
    'noautocmd set filetype=%s',
    vim.fn.substitute(vim.bo.filetype, 'typescriptreact', 'typescript.tsx', '')
  )
)
