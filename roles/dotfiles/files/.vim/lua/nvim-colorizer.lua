local colorizer = require 'colorizer'

-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
colorizer.setup ({
    '*';
    '!vim';
  }, {
    css  = true;
  })
