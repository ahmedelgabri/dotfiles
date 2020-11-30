augroup MyAutoCmds
  autocmd!
  " Automatically make splits equal in size
  autocmd VimResized * wincmd =

  " Disable paste mode on leaving insert mode.
  autocmd InsertLeave * set nopaste

  " autocmd InsertLeave,VimEnter,WinEnter * setlocal cursorline
  " autocmd InsertEnter,WinLeave * setlocal nocursorline

  " taken from https://github.com/jeffkreeftmeijer/vim-numbertoggle/blob/cfaecb9e22b45373bb4940010ce63a89073f6d8b/plugin/number_toggle.vim
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu | set nornu | endif

  " See https://github.com/neovim/neovim/issues/7994
  autocmd InsertLeave * set nopaste

  autocmd BufEnter,BufWinEnter,BufRead,BufNewFile bookmarks.{md,txt} hi! link mkdLink Normal | set concealcursor-=n

  if executable('direnv')
    autocmd BufWritePost .envrc silent !direnv allow %
  endif

  if has('mksession') && has('folding') && has('nvim')
    autocmd BufReadPre * lua require'_.autocmds'.disable_heavy_plugins()
    autocmd BufWritePost,BufLeave,WinLeave ?* lua require'_.autocmds'.mkview()
    autocmd BufWinEnter ?* lua require'_.autocmds'.loadview()
    " Close preview buffer with q
    autocmd FileType * lua require'_.autocmds'.quit_on_q()
    " Project specific override
    autocmd BufRead,BufNewFile * lua require'_.autocmds'.source_project_config()

    if has('##DirChanged')
      autocmd DirChanged * lua require'_.autocmds'.source_project_config()
    endif

    autocmd BufWritePre * Format
    autocmd BufWritePost plugins.lua PackerCompile
  endif

  if exists('##TextYankPost')
    autocmd TextYankPost * silent! lua return (not vim.v.event.visual) and require'vim.highlight'.on_yank("IncSearch", 200)
  endif

  autocmd BufWritePost */spell/*.add silent! :mkspell! %
augroup END
