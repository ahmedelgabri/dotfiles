local pack = require '_.pack'

pack.add {
	{
		src = 'https://github.com/wincent/shannon',
		config = function()
			require('wincent.shannon').setup {
				prefix = '<LocalLeader>a', -- keymap prefix
				agents = { 'pi', 'claude' }, -- process names to search for, in priority order
			}
		end,
	},
}
