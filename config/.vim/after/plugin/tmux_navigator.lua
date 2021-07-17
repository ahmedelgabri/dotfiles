if vim.env.TMUX ~= nil and vim.fn.exists 'g:loaded_tmux_navigator' == 0 then
  vim.cmd [[packadd vim-tmux-navigator]]
  vim.g.tmux_navigator_disable_when_zoomed = 1
end
