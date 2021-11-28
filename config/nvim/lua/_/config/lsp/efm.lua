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

local languages = {
  vim = { vint },
  go = { golint },
  python = { pylint },
  sh = { shellcheck },
  bash = { shellcheck },
  dockerfile = { hadolint },
}

return {
  -- cmd = {"efm-langserver", "-logfile", "/tmp/efm.log", "-loglevel", "5"},
  init_options = { documentFormatting = false, codeAction = true },
  filetypes = vim.tbl_keys(languages), -- needed to work on new buffers
  settings = {
    rootMarkers = { '.git/', vim.loop.cwd() },
    languages = languages,
  },
}
