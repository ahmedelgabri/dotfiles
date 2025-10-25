local utils = require '_.utils'

vim.bo.iskeyword = utils.remove(vim.bo.iskeyword, '#')
