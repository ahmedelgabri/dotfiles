local pack = require '_.pack'

pack.add {
	{
		-- The fork's `rex` branch adds Rex support; upstream is tmux-only.
		src = 'https://github.com/ahmedelgabri/shannon',
		version = 'rex',
		config = function()
			require('wincent.shannon').setup {
				prefix = '<LocalLeader>a', -- keymap prefix
				agents = { 'pi', 'claude' }, -- process names to search for, in priority order
			}
		end,
	},
}
