vim.cmd [[
if &diff
  syntax off
  set number
else
  syntax on
  set number&
endif
]]
