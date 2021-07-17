if vim.fn.executable 'rg' == 0 then
  return
end

vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden'
vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
vim.cmd [[nnoremap \ :silent grep!  \| cwindow<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>]]
