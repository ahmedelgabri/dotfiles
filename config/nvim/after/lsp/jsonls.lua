return {
	settings = {
		json = {
			validate = { enable = true },
			format = { enable = true },
			schemas = require('schemastore').json.schemas {},
		},
	},
}
