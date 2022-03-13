if vim.fn.exists ':FZF' == 0 then
  return
end

__.fzf = {}

local map = require '_.utils.map'
local au = require '_.utils.au'

if vim.env.FZF_CTRL_T_OPTS ~= nil then
  vim.g.fzf_files_options = vim.env.FZF_CTRL_T_OPTS
end

if vim.env.VIM_FZF_LOG ~= nil then
  vim.g.fzf_commits_log_options = vim.env.VIM_FZF_LOG
end

vim.g.fzf_layout = { window = { width = 0.9, height = 0.8, relative = false } }
vim.g.fzf_history_dir = vim.fn.expand '~/.fzf-history'
vim.g.fzf_buffers_jump = 1
vim.g.fzf_tags_command = 'ctags -R'
vim.g.fzf_preview_window = 'right:border-left'

map.imap('<c-x><c-k>', '<plug>(fzf-complete-word)')
map.imap('<c-x><c-f>', '<plug>(fzf-complete-path)')
map.imap('<c-x><c-j>', '<plug>(fzf-complete-file-ag)')
map.imap('<c-x><c-l>', '<plug>(fzf-complete-line)')

-- Override Files to show resposnive UI depending on the window width & start with a hidden preview window
vim.cmd [[command! -bang -nargs=? -complete=dir Files call fzf#vim#files(<q-args>, &columns > 90 ? fzf#vim#with_preview('right:border-left:hidden') : fzf#vim#with_preview('down:border-top'), <bang>0)]]
map.nnoremap('<leader><leader>', ':Files<CR>', { silent = true })
map.nnoremap('<Leader>b', ':Buffers<cr>', { silent = true })
map.nnoremap('<Leader>h', ':Helptags<cr>', { silent = true })
map.nnoremap('<Leader>o', ':History<cr>', { silent = true })

au.augroup('__my_fzf__', function()
  au.autocmd(
    'User',
    'FzfStatusLine',
    [[setlocal statusline=%4*\ fzf\ %6*V:\ ctrl-v,\ H:\ ctrl-x,\ Tab:\ ctrl-t]]
  )
end)

function FzfSpellSink(word)
  vim.fn.execute('normal! "_ciw' .. word)
end

function __.fzf.FzfSpell()
  local suggestions = vim.fn.spellsuggest(vim.fn.expand '<cword>')
  return vim.fn['fzf#run'] {
    source = suggestions,
    sink = FzfSpellSink,
    down = 25,
  }
end

map.nnoremap('z=', ':call v:lua.__.fzf.FzfSpell()<CR>', { silent = true })

-- https://github.com/junegunn/fzf.vim/issues/907#issuecomment-554699400
function __.fzf.RipgrepFzf(query, fullscreen)
  local command_fmt =
    'rg --column --line-number --no-heading --color=always -g "!*.lock" -g "!*lock.json" --smart-case %s || true'
  local initial_command = string.format(command_fmt, vim.fn.shellescape(query))
  local reload_command = string.format(command_fmt, '{q}')
  local spec = {
    options = {
      '--phony',
      '--query',
      query,
      '--bind',
      'change:reload:' .. reload_command,
    },
  }
  vim.fn['fzf#vim#grep'](
    initial_command,
    1,
    vim.fn['fzf#vim#with_preview'](spec),
    fullscreen
  )
end

vim.cmd [[command! -nargs=* -bang RG call v:lua.__.fzf.RipgrepFzf(<q-args>, <bang>0)]]
map.nnoremap([[<leader>\]], [[:RG<CR>]])
