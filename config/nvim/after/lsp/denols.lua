local utils = require '_.utils'

return {
	root_dir = utils.root_for { 'deno.json', 'deno.jsonc' },
}
