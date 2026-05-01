Pack.add { 'https://github.com/wincent/shannon' }

require('wincent.shannon').setup {
	prefix = '<LocalLeader>a', -- keymap prefix
	agents = { 'pi', 'claude' }, -- process names to search for, in priority order
}
