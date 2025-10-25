local au = require '_.utils.au'

if vim.fn.executable 'jq' == 1 then
	vim.bo.formatprg = 'jq .'
else
	vim.bo.formatprg = 'python -m json.tool'
end

vim.g.vim_json_conceal = 0
vim.wo.conceallevel = 0

au.augroup('__JSON__', {
	{
		event = { 'BufRead', 'BufNewFile' },
		pattern = 'package.json',
		callback = function()
			vim.keymap.set({ 'n' }, 'gx', function()
				local line = vim.fn.getline '.'
				local _, _, package, _ = string.find(line, [[^%s*"(.*)":%s*"(.*)"]])

				if package then
					local url = 'https://www.npmjs.com/package/' .. package
					vim.ui.open(url)
				end
			end, { buffer = true, silent = true, desc = '[G]o to [p]ackage' })
		end,
	},
})
