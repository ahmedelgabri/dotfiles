if vim.fn.exists 'g:loaded_projectionist' == 0 then
  return
end

vim.g.projectionist_ignore_term = 1
vim.g.projectionist_ignore_man = 1

vim.g.projectionist_heuristics = {
  ['&bsconfig.json'] = {
    ['src/*.re'] = {
      alternate = {
        '__tests__/{}_test.re',
        'src/{}_test.re',
        'src/{}.rei',
      },
      type = 'source',
    },
    ['src/*.rei'] = {
      alternate = {
        'src/{}.re',
        '__tests__/{}_test.re',
        'src/{}_test.re',
      },
      type = 'header',
    },
    ['__tests__/*_test.re'] = {
      alternate = {
        'src/{}.rei',
        'src/{}.re',
      },
      type = 'test',
    },
  },
  ['&package.json'] = {
    ['package.json'] = {
      type = 'package',
      alternate = { 'yarn.lock', 'package-lock.json' },
    },
    ['package-lock.json'] = {
      alternate = 'package.json',
    },
    ['yarn.lock'] = {
      alternate = 'package.json',
    },
  },
}

-- Helper function for batch-updating the g:projectionist_heuristics variable.
local function project(root, ...)
  for _, tbl in pairs { ... } do
    local pattern, projection = unpack(tbl)

    vim.g.projectionist_heuristics = vim.tbl_deep_extend(
      'force',
      vim.g.projectionist_heuristics,
      { ['&' .. root] = { [pattern] = projection } }
    )
  end
end

-- Set up projections for JS variants.
for _, tbl in pairs {
  { 'package.json', '.js' },
  { 'package.json', '.jsx' },
  { 'tsconfig.json', '.ts' },
  { 'tsconfig.json', '.tsx' },
} do
  local root, extension = unpack(tbl)

  project(root, {
    '*' .. extension,
    {
      alternate = {
        '{dirname}/{file|dirname|basename}.test' .. extension,
        '{dirname}/__tests__/{basename}.test' .. extension,
      },
      type = 'source',
    },
  }, {
    '*.test' .. extension,
    {
      alternate = {
        '{file|dirname}' .. extension,
        '{file|dirname}/index' .. extension,
      },
      type = 'test',
    },
  }, {
    '**/__tests__/*.test' .. extension,
    {
      alternate = {
        '{dirname}/{basename}' .. extension,
        '{dirname}/{basename}/index' .. extension,
      },
      type = 'test',
    },
  })
end
