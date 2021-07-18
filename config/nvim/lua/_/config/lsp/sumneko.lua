local cache_location = vim.fn.stdpath 'cache'
local bin_folder = jit.os:lower() == 'osx' and 'macOS' or jit.os

local nlua_nvim_lsp = {
  base_directory = string.format(
    '%s/nlua/sumneko_lua/lua-language-server/',
    cache_location
  ),
  bin_location = string.format(
    '%s/nlua/sumneko_lua/lua-language-server/bin/%s/lua-language-server',
    cache_location,
    bin_folder
  ),
}

local sumneko_command = function()
  return {
    nlua_nvim_lsp.bin_location,
    '-E',
    string.format('%s/main.lua', nlua_nvim_lsp.base_directory),
  }
end

local function get_lua_runtime()
  local result = {}
  for _, path in pairs(vim.api.nvim_list_runtime_paths()) do
    local lua_path = path .. '/lua/'
    if vim.fn.isdirectory(lua_path) then
      result[lua_path] = true
    end
  end

  -- This loads the `lua` files from nvim into the runtime.
  result[vim.fn.expand '$VIMRUNTIME/lua'] = true
  result[vim.fn.expand '$VIMRUNTIME/lua/vim/lsp'] = true

  return result
end

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')

return {
  cmd = sumneko_command(),
  filetypes = { 'lua' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
      -- completion = {
      --   keywordSnippet = "Disable"
      -- },
      diagnostics = {
        enable = true,
        -- Neovim & Hammerspoon
        globals = { 'vim', 'spoon', 'hs' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
      },
      telemetry = { enable = false },
    },
  },
}
