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

return require('lua-dev').setup {
  lspconfig = {
    cmd = sumneko_command(),
    settings = {
      Lua = {
        diagnostics = {
          globals = {
            'vim',
            'describe',
            'it',
            'before_each',
            'after_each',
            'pending',
            'teardown',
            'packer_plugins',
            'spoon',
            'hs',
          },
        },
        completion = { keywordSnippet = 'Replace', callSnippet = 'Replace' },
        telemetry = { enable = false },
      },
    },
  },
}
