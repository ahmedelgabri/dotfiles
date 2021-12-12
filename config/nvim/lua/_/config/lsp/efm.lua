-- Formatters

local prettier = {
  formatCommand = string.format(
    table.concat({
      'prettier', -- this will work because I have prettier globally & in projects direnv will add `node_modules/bin` to $PATH
      '--config-precedence prefer-file',
      '--single-quote',
      '--no-bracket-spacing',
      '--prose-wrap always',
      '--arrow-parens always',
      '--trailing-comma all',
      '--no-semi',
      '--end-of-line lf',
      '--print-width',
      '%s',
      '--stdin-filepath ${INPUT}',
    }, ' '),
    vim.bo.textwidth <= 80 and 80 or vim.bo.textwidth
  ),
  formatStdin = true,
}

local gofmt = {
  formatCommand = 'gofmt',
  formatStdin = true,
}

local goimports = {
  formatCommand = 'goimports',
  formatStdin = true,
}

local shfmt = {
  formatCommand = 'shfmt -',
  formatStdin = true,
}

local refmt = {
  formatCommand = 'refmt',
  formatStdin = true,
}

local rustfmt = {
  formatCommand = 'rustfmt',
  formatStdin = true,
}

local black = {
  formatCommand = 'black --quiet -',
  formatStdin = true,
}

local nixfmt = {
  formatCommand = 'nixpkgs-fmt',
  formatStdin = true,
}

local statixfmt = {
  formatCommand = 'statix fix --stdin',
  formatStdin = true,
}

local stylua = {
  formatCommand = string.format(
    table.concat({
      'stylua',
      '--indent-type Spaces',
      '--line-endings Unix',
      '--quote-style AutoPreferSingle',
      '--indent-width %s',
      '--column-width %s',
      '-',
    }, ' '),
    vim.bo.tabstop,
    vim.bo.textwidth <= 80 and 80 or vim.bo.textwidth
  ),
  formatStdin = true,
}

local jsonfmt = {
  formatCommand = 'jq',
  formatStdin = true,
}

-- Linters

local shellcheck = {
  lintCommand = 'shellcheck --format=gcc --external-sources -',
  lintStdin = true,
  lintFormats = {
    '%f:%l:%c: %trror: %m',
    '%f:%l:%c: %tarning: %m',
    '%f:%l:%c: %tote: %m',
  },
  lintSource = 'shellcheck',
}

local pylint = {
  lintCommand = "pylint --output-format text --reports n --msg-template='{path}:{line}:{column}: {msg_id} ({symbol}) {msg}' ${INPUT}",
  lintIgnoreExitCode = true,
  lintStdin = false,
  lintFormats = {
    '%f:%l:%c:%t:%m',
  },
  lintSource = 'pylint',
  lintOffsetColumns = 1,
  lintCategoryMap = {
    I = 'H',
    R = 'I',
    C = 'I',
    W = 'W',
    E = 'E',
    F = 'E',
  },
}

local golint = {
  lintCommand = 'golint',
  lintIgnoreExitCode = true,
  lintFormats = { '%f:%l:%c: %m' },
  lintSource = 'golint',
}

local hadolint = {
  lintCommand = 'hadolint',
  lintFormats = { '%f:%l %m' },
  lintSource = 'hadolint',
}

local vint = {
  lintCommand = 'vint -',
  lintStdin = true,
  lintFormats = { '%f:%l:%c: %m' },
  lintSource = 'vint',
}

local statix = {
  lintCommand = 'statix check --stdin --format=errfmt',
  lintStdin = true,
  lintIgnoreExitCode = true,
  lintFormats = { '%f>%l:%c:%t:%n:%m' },
  lintSource = 'statix',
}

local nixlinter = {
  lintCommand = 'nix-linter -',
  lintStdin = true,
  lintFormats = { '%m at %f:%l:%c' },
  lintSource = 'nix-linter',
}

<<<<<<< HEAD
local selene = {
  lintSource = 'selene',
  lintCommand = 'selene --quiet -',
  lintStdin = true,
  lintFormats = {
    '-:%l:%c: %tarning[%.%+]: %m',
    '-:%l:%c: %trror[%.%+]: %m',
  },
}

local languages = {
  json = { jsonfmt },
  vim = { vint },
  go = { goimports, gofmt, golint },
  python = { black, pylint },
  sh = { shfmt, shellcheck },
  bash = { shfmt, shellcheck },
  dockerfile = { hadolint },
  nix = { nixfmt, statixfmt, nixlinter, statix },
  reason = { refmt },
  rust = { rustfmt },
  lua = { stylua, selene },
}

for _, value in ipairs {
  'typescript',
  'javascript',
  'typescript.tsx',
  'javascript.jsx',
  'typescriptreact',
  'javascriptreact',
  'vue',
  'yaml',
  'html',
  'scss',
  'css',
  'markdown',
  'mdx',
  'json',
} do
  if not languages[value] then
    languages[value] = { prettier }
  end
end

return {
  -- cmd = {"efm-langserver", "-logfile", "/tmp/efm.log", "-loglevel", "5"},
  init_options = { documentFormatting = true, codeAction = true },
  filetypes = vim.tbl_keys(languages), -- needed to work on new buffers
  settings = {
    rootMarkers = { '.git/', vim.loop.cwd() },
    languages = languages,
  },
}
