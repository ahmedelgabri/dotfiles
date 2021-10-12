return function()
  local au = require '_.utils.au'

  vim.g.vim_markdown_fenced_languages = {
    'css',
    'erb=eruby',
    'javascript',
    'js=javascript',
    'jsx=javascript.jsx',
    'ts=typescript',
    'tsx=typescript.tsx',
    'json=jsonc',
    'ruby',
    'sass',
    'scss=sass',
    'xml',
    'html',
    'py=python',
    'python',
    'clojure',
    'clj=clojure',
    'clojurescript',
    'cljs=clojurescript',
    'stylus=css',
    'less=css',
    'viml=vim',
  }
end
