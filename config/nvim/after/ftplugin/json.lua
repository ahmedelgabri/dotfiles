if vim.fn.executable 'jq' == 1 then
	vim.bo.formatprg = 'jq .'
else
	vim.bo.formatprg = 'python -m json.tool'
end

vim.g.vim_json_conceal = 0
vim.wo.conceallevel = 0

if vim.fn.expand '%:t' == 'package.json' then
	vim.keymap.set('n', 'gx', function()
		local line = vim.fn.getline '.'
		local _, _, pkg = string.find(line, [[^%s*"([^"]*)"%s*:%s*"([^"]*)"]])

		if pkg then
			local url = 'https://www.npmjs.com/package/' .. pkg
			vim.ui.open(url)
		end
	end, { buf = 0, silent = true, desc = '[G]o to [p]ackage' })
end
