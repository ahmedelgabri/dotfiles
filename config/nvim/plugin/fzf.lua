local pack = require '_.pack'
local utils = require '_.utils'

vim.g.fzf_history_dir = vim.fn.expand '~/.fzf-history'
vim.g.fzf_layout = vim.env.TMUX ~= nil and { popup = 'center,85%,85%' }
	or {
		window = {
			width = 0.85,
			height = 0.85,
			relative = true,
			border = utils.get_border(),
		},
	}

-- Keep this in sync with `git config alias.l`.
local git_log_args =
	[[--color=always --graph --pretty=format:"%C(blue)%h %Creset- %C(green)%>(12)(%cr) %Creset%s - %C(cyan)%aN %C(magenta)%d" --date=auto:human]]

vim.g.fzf_vim = {
	commits_log_options = git_log_args,
	files_options = { '--walker-skip', '.git,node_modules' },
	preview_window = { 'right:border-left:60%:hidden' },
}

pack.add {
	{
		src = 'https://github.com/junegunn/fzf',
		name = 'fzf',
		event = { 'UIEnter' },
	},
	{
		src = 'https://github.com/junegunn/fzf.vim',
		event = { 'UIEnter' },
		config = function()
			local function with_preview(spec, placeholder, visible, offset)
				spec = spec or {}
				spec.options = spec.options or {}

				local command = vim.env.FZF_PREVIEW_COMMAND
					or 'COLORTERM=truecolor previewer {}'
				command = command:gsub('{}', placeholder or '{}', 1)

				local preview_window = 'right:border-left:60%'
					.. (visible and '' or ':hidden')
				if offset ~= nil then
					preview_window = preview_window .. ':' .. offset
				end

				vim.list_extend(spec.options, {
					'--preview',
					command,
					'--preview-window',
					preview_window,
				})
				return spec
			end

			local function grep_spec(prompt)
				local spec = with_preview({
					options = {
						'--bind',
						'ctrl-q:select-all+accept',
					},
				}, '{1} {2}', true, '+{2}/2')
				if prompt ~= nil then
					vim.list_extend(spec.options, { '--prompt', prompt })
				end
				return spec
			end

			local function grep_project(pattern, prompt)
				local command = table.concat({
					'rg --column --line-number --no-heading --color=always',
					'--smart-case --hidden --no-ignore -e',
					vim.fn['fzf#shellescape'](pattern),
				}, ' ')
				vim.fn['fzf#vim#grep'](command, grep_spec(prompt), false)
			end

			local function spell_suggest()
				local suggestions = vim.fn.spellsuggest(vim.fn.expand '<cword>')
				if vim.tbl_isempty(suggestions) then
					return
				end

				local spec = vim.fn['fzf#wrap']('spell', {
					source = suggestions,
					sink = function(word)
						vim.cmd.normal { args = { '"_ciw' .. word }, bang = true }
					end,
					options = {
						'--prompt',
						'Spell Suggestions> ',
						'--no-multi',
						'--no-preview',
					},
				}, false)
				vim.fn['fzf#run'](spec)
			end

			vim.keymap.set('n', '<leader><leader>', function()
				vim.fn['fzf#vim#files']('', with_preview(nil, nil, true), false)
			end, { silent = true, desc = 'Search Files' })

			vim.keymap.set('n', '<leader>b', function()
				vim.fn['fzf#vim#buffers'](
					'',
					with_preview({}, '{4}', true, '+{2}/2'),
					false
				)
			end, { silent = true, desc = 'Search [B]uffers' })

			vim.keymap.set('n', '<leader>h', '<Cmd>Helptags<CR>', {
				silent = true,
				desc = 'Search [H]elp',
			})

			vim.keymap.set('n', '<Leader>o', '<Cmd>History<CR>', {
				silent = true,
				desc = 'Search [O]ldfiles',
			})

			vim.keymap.set('n', '<Leader>\\', function()
				vim.fn['fzf#vim#grep2'](
					'rg --column --line-number --no-heading --color=always --smart-case --',
					'',
					grep_spec(),
					false
				)
			end, { silent = true, desc = 'grep project' })

			vim.keymap.set('n', '<leader>ta', function()
				grep_project([=[^\s*- \[ \]]=], 'Tasks> ')
			end, { desc = 'Search for incomplete t[a]sks' })

			vim.keymap.set('n', '<leader>to', function()
				grep_project(
					[[^\s*?(//|#|--|%|;|/\*)\s*@?(todo|note|hack|bug|fixme|fix|warn|xxx):?\b]],
					'TODOs> '
				)
			end, { desc = 'Search for t[o]dos' })

			vim.keymap.set('n', 'z=', spell_suggest, {
				silent = true,
				desc = 'Spelling Suggestions',
			})
		end,
	},
}
