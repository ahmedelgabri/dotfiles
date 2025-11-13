-- https://github.com/wincent/wincent/blob/5ab9e1fbe302b1a5948eb6e00ff4b2875ee24674/aspects/nvim/files/.config/nvim/lua/wincent/lsp.lua#L203-L250
local config_directory = vim.fn.stdpath 'config'

--- @param a string A path
--- @param b string A possible prefix matching or included in that path
--- @return boolean Does path `a` include `b` as a prefix?
local function has_prefix(a, b)
	return string.sub(a .. '/', 1, #(b .. '/')) == (b .. '/')
end

-- `nvim_get_runtime_file()` will return:
--
-- - The top-level config path (ie. "~/.config/nvim")
-- - Special folders inside the top-level, like "~/.config/nvim/after"
-- - Plug-in paths like "~/.config/nvim/pack/bundle/opt/command-t"
-- - System paths like "/opt/homebrew/Cellar/neovim/0.11.2/share/nvim/runtime"
--
-- If we include paths that are nested inside other paths
-- lua-language-server will actually read some files more than once, and
-- produce spurious `duplicate-doc-field` diagnostics.
--
-- Additionally, passing our own config file or plug-in files into
-- "workspace.library" is likely a misuse of the setting; the docs state
-- it is for "library implementation code and definition files" (the later
-- should generally be tagged with `@meta`, and not include executable Lua
-- code).
--
-- So, filter out the main config path and anything that's under it. This
-- is what definitively resolves the `duplicate-doc-field` diagnostics.
--
-- See:
-- - https://github.com/neovim/nvim-lspconfig/issues/3189
-- - https://github.com/LuaLS/lua-language-server/issues/2061
-- - https://luals.github.io/wiki/settings/#workspacelibrary
-- - https://luals.github.io/wiki/definition-files/
local function get_library_directories(options)
	local filter = options and options.filter or false
	local runtime_directories = vim.api.nvim_get_runtime_file('', true)
	if filter then
		return vim.tbl_filter(function(path)
			-- Keep directory unless it coincides with the config directory (or
			-- is inside it).
			return not has_prefix(path, config_directory)
		end, runtime_directories)
	else
		return runtime_directories
	end
end

return {
	root_markers = {
		{
			'.emmyrc.json',
			'.luarc.json',
			'.luarc.jsonc',
			'.luacheckrc',
			'.stylua.toml',
			'stylua.toml',
		},
		'.git',
	},
	settings = {
		Lua = {
			workspace = {
				ignoreDir = {
					'.direnv',
				},
			},
		},
	},
	on_init = function(client)
		if client.workspace_folders then
			-- Found a root marker.
			local path = client.workspace_folders[1].name
			if
				vim.uv.fs_stat(path .. '/.emmyrc.json')
				or vim.uv.fs_stat(path .. '/.luarc.json')
				or vim.uv.fs_stat(path .. '/.luarc.jsonc')
			then
				return
			end

			-- Is the workspace somewhere under "~/.nvim/config" or any runtime
			-- directory?
			local real_workspace_path = vim.uv.fs_realpath(path)
			local library_directories = get_library_directories()
			for _, library_directory in ipairs(library_directories) do
				local real_library_directory_path =
					vim.uv.fs_realpath(library_directory)
				if
					real_workspace_path
					and real_library_directory_path
					and has_prefix(real_workspace_path, real_library_directory_path)
				then
					-- Provide defaults for my common case (working on Neovim Lua).
					client.config.settings.Lua =
						vim.tbl_deep_extend('force', client.config.settings.Lua, {
							diagnostics = {
								enable = true,
								globals = { 'vim' },
							},
							runtime = {
								requirePattern = {
									-- Load modules the same was as Neovim does (see `:help lua-module-load`).
									'lua/?.lua',
									'lua/?/init.lua',
								},
								version = 'LuaJIT',
							},
							workspace = {
								-- Make the server aware of Neovim runtime files.
								library = get_library_directories { filter = true },
							},
						})

					client:notify(
						'workspace/didChangeConfiguration',
						{ settings = client.config.settings }
					)
				end
			end
		end
	end,
}
