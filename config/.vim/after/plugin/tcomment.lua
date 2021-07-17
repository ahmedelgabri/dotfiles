local map = require '_.utils.map'

-- Prevent tcomment from making a zillion mappings (we just want the operator).
vim.g.tcomment_mapleader1 = ''
vim.g.tcomment_mapleader2 = ''
vim.g.tcomment_mapleader_comment_anyway = ''
vim.g.tcomment_textobject_inlinecomment = ''
-- The default (g<) is a bit awkward to type.
vim.g.tcomment_mapleader_uncomment_anyway = 'gu'

--  Uncomment a line; mirrors gcc (which comments/toggles a line).
map.nmap('guu', '<Plug>TComment_Uncommentc')
map.xmap('gu', '<Plug>TComment_Uncommentc')
