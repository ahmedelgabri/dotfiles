local utils = require '_.utils'

return {
	cmd = { utils.get_lsp_bin 'oxc_language_server' },
}
