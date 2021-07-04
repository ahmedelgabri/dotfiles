local prettier = {
  formatCommand = string.format(
    table.concat(
      {
        "prettier", -- this will work because I have prettier globally & in projects direnv will add `node_modules/bin` to $PATH
        "--config-precedence prefer-file",
        "--single-quote",
        "--no-bracket-spacing",
        "--prose-wrap always",
        "--arrow-parens always",
        "--trailing-comma all",
        "--no-semi",
        "--end-of-line lf",
        "--print-width",
        "%s",
        "--stdin-filepath ${INPUT}"
      },
      " "
    ),
    vim.bo.textwidth
  ),
  formatStdin = true
}

local eslint = {
  -- this will work because I have prettier globally & in projects direnv will add `node_modules/bin` to $PATH
  lintCommand = "eslint --format visualstudio --stdin --stdin-filename ${INPUT}",
  lintIgnoreExitCode = true,
  lintStdin = true,
  lintFormats = {
    "%f(%l,%c): %tarning %m",
    "%f(%l,%c): %rror %m"
  },
  lintSource = "eslint"
}

local shellcheck = {
  lintCommand = "shellcheck --format=gcc --external-sources -",
  lintStdin = true,
  lintFormats = {
    "%f:%l:%c: %trror: %m",
    "%f:%l:%c: %tarning: %m",
    "%f:%l:%c: %tote: %m"
  },
  lintSource = "shellcheck"
}

local shfmt = {
  formatCommand = "shfmt -",
  formatStdin = true
}

local black = {
  formatCommand = "black --quiet -",
  formatStdin = true
}

local pylint = {
  lintCommand = "pylint --output-format text --reports n --msg-template='{path}:{line}:{column}: {msg_id} ({symbol}) {msg}' ${INPUT}",
  lintIgnoreExitCode = true,
  lintStdin = false,
  lintFormats = {
    "%f:%l:%c:%t:%m"
  },
  lintSource = "pylint",
  lintOffsetColumns = 1,
  lintCategoryMap = {
    I = "H",
    R = "I",
    C = "I",
    W = "W",
    E = "E",
    F = "E"
  }
}

local luafmt = {
  formatCommand = string.format(
    "luafmt --indent-count 2 --line-width %s --stdin",
    vim.bo.textwidth
  ),
  formatStdin = true
}

local nixfmt = {
  formatCommand = "nixpkgs-fmt",
  formatStdin = true
}

local rustfmt = {
  formatCommand = "rustfmt",
  formatStdin = true
}

local gofmt = {
  formatCommand = "gofmt",
  formatStdin = true
}

local refmt = {
  formatCommand = "refmt",
  formatStdin = true
}

local golint = {
  lintCommand = "golint",
  lintIgnoreExitCode = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintSource = "golint"
}

local hadolint = {
  lintCommand = "hadolint",
  lintFormats = {"%f:%l %m"},
  lintSource = "hadolint"
}

local vint = {
  lintCommand = "vint -",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintSource = "vint"
}

local languages = {
  vim = {vint},
  lua = {luafmt},
  rust = {rustfmt},
  reason = {refmt},
  rescript = {refmt},
  go = {gofmt, golint},
  nix = {nixfmt},
  python = {black, pylint},
  typescript = {prettier, eslint},
  javascript = {prettier, eslint},
  ["typescript.tsx"] = {prettier, eslint},
  ["javascript.jsx"] = {prettier, eslint},
  typescriptreact = {prettier, eslint},
  javascriptreact = {prettier, eslint},
  vue = {prettier},
  yaml = {prettier},
  json = {prettier},
  html = {prettier},
  scss = {prettier},
  css = {prettier},
  markdown = {prettier},
  sh = {shfmt, shellcheck},
  bash = {shfmt, shellcheck},
  dockerfile = {hadolint}
}

return {
  -- cmd = {"efm-langserver", "-logfile", "/tmp/efm.log", "-loglevel", "5"},
  init_options = {documentFormatting = true, codeAction = true},
  root_dir = vim.loop.cwd,
  filetypes = vim.tbl_keys(languages), -- needed to work on new buffers
  settings = {
    rootMarkers = {".git/", vim.loop.cwd()},
    languages = languages
  }
}
