-- Only required if you have packer in your `opt` pack
local packer_exists = pcall(vim.cmd, [[packadd packer.nvim]])

if not packer_exists then
  if vim.fn.input("Download Packer? (y for yes) ") ~= "y" then
    return
  end

  local directory =
    string.format("%s/pack/packer/opt/", vim.fn.stdpath("config"))

  vim.fn.mkdir(directory, "p")

  local out =
    vim.fn.system(
    string.format(
      "git clone %s %s",
      "https://github.com/wbthomason/packer.nvim",
      directory .. "/packer.nvim"
    )
  )

  print(out)
  print("Downloading packer.nvim...")

  return
end

local packer = require "packer"
local lisps = {"lisp", "scheme", "clojure"}
local plugins = {
  {"https://github.com/wbthomason/packer.nvim", opt = true},
  {"https://github.com/antoinemadec/FixCursorHold.nvim"},
  {"https://github.com/andymass/vim-matchup"},
  {"https://github.com/tpope/vim-sensible", opt = true},
  {"https://github.com/jiangmiao/auto-pairs"},
  {
    "https://github.com/junegunn/fzf.vim",
    -- I have the bin globally, so don't build, and just grab plugin directory
    requires = {{"https://github.com/junegunn/fzf"}}
  },
  {
    "https://github.com/lambdalisue/fern-git.vim",
    requires = {{"https://github.com/lambdalisue/fern.vim"}}
  },
  {"https://github.com/duggiefresh/vim-easydir"},
  {"https://github.com/junegunn/vim-peekaboo"},
  {
    "https://github.com/mbbill/undotree",
    opt = true,
    cmd = "UndotreeToggle"
  },
  {"https://github.com/mhinz/vim-grepper", opt = true, cmd = "Grepper"},
  {"https://github.com/mhinz/vim-sayonara", opt = true, cmd = "Sayonara"},
  {"https://github.com/mhinz/vim-startify"},
  {"https://github.com/nelstrom/vim-visual-star-search"},
  {"https://github.com/tpope/tpope-vim-abolish"},
  {"https://github.com/tpope/vim-eunuch"},
  -- {'https://github.com/tpope/vim-projectionist'},
  {"https://github.com/tpope/vim-repeat"},
  {
    "https://github.com/machakann/vim-sandwich",
    config = function()
      vim.cmd("runtime macros/sandwich/keymap/surround.vim")
      vim.g["sandwich#recipes"] =
        vim.tbl_extend(
        "force",
        vim.g["sandwich#recipes"],
        {
          {
            buns = {[[/\*\s*]], [[\s*\*/]]},
            regex = 1,
            filetype = {
              "typescript",
              "typescriptreact",
              "typescript.tsx",
              "javascript",
              "javascriptreact",
              "javascript.jsx"
            },
            input = {"/"}
          },
          {
            buns = {"${", "}"},
            filetype = {
              "typescript",
              "typescriptreact",
              "typescript.tsx",
              "javascript",
              "javascriptreact",
              "javascript.jsx",
              "zsh",
              "bash",
              "shell",
              "nix"
            },
            input = {"$"}
          }
        }
      )
    end
  },
  {"https://github.com/tomtom/tcomment_vim"},
  {"https://github.com/wellle/targets.vim"},
  {"https://github.com/wincent/loupe"},
  {"https://github.com/wincent/terminus"},
  {"https://github.com/tommcdo/vim-lion"},
  {"https://github.com/liuchengxu/vista.vim"},
  {"https://github.com/christoomey/vim-tmux-navigator", opt = true},
  {"https://github.com/rhysd/devdocs.vim"},
  {"https://github.com/fcpg/vim-waikiki"},
  -- LSP/Autocompletion {{{
  {
    "https://github.com/neovim/nvim-lspconfig",
    cond = "vim.fn.has('nvim-0.5.0')",
    config = function()
      require "_.lsp"
    end,
    requires = {
      {
        "https://github.com/tjdevries/lsp_extensions.nvim",
        config = function()
          require "_.statusline".activate()
        end
      },
      {"https://github.com/tjdevries/nlua.nvim"},
      {
        "https://github.com/gfanto/fzf-lsp.nvim",
        config = function()
          vim.lsp.handlers["textDocument/codeAction"] =
            require "fzf_lsp".code_action_handler
          vim.lsp.handlers["textDocument/definition"] =
            require "fzf_lsp".definition_handler
          vim.lsp.handlers["textDocument/declaration"] =
            require "fzf_lsp".declaration_handler
          vim.lsp.handlers["textDocument/typeDefinition"] =
            require "fzf_lsp".type_definition_handler
          vim.lsp.handlers["textDocument/implementation"] =
            require "fzf_lsp".implementation_handler
          vim.lsp.handlers["textDocument/references"] =
            require "fzf_lsp".references_handler
          vim.lsp.handlers["textDocument/documentSymbol"] =
            require "fzf_lsp".document_symbol_handler
          vim.lsp.handlers["workspace/symbol"] =
            require "fzf_lsp".workspace_symbol_handler
        end
      }
      -- {
      --   "https://github.com/RishabhRD/nvim-lsputils",
      --   config = function()
      --     vim.lsp.handlers["textDocument/codeAction"] =
      --       require "lsputil.codeAction".code_action_handler
      --     vim.lsp.handlers["textDocument/references"] =
      --       require "lsputil.locations".references_handler
      --     vim.lsp.handlers["textDocument/definition"] =
      --       require "lsputil.locations".definition_handler
      --     vim.lsp.handlers["textDocument/declaration"] =
      --       require "lsputil.locations".declaration_handler
      --     vim.lsp.handlers["textDocument/typeDefinition"] =
      --       require "lsputil.locations".typeDefinition_handler
      --     vim.lsp.handlers["textDocument/implementation"] =
      --       require "lsputil.locations".implementation_handler
      --     vim.lsp.handlers["textDocument/documentSymbol"] =
      --       require "lsputil.symbols".document_handler
      --     vim.lsp.handlers["workspace/symbol"] =
      --       require "lsputil.symbols".workspace_handler
      --   end,
      --   requires = {{"https://github.com/RishabhRD/popfix", run = "make"}}
      -- }
    }
  },
  {
    "https://github.com/nvim-lua/completion-nvim",
    requires = {
      {
        "https://github.com/steelsojka/completion-buffers",
        cond = "vim.fn.has('nvim-0.5.0')"
      },
      {"https://github.com/hrsh7th/vim-vsnip"},
      {"https://github.com/hrsh7th/vim-vsnip-integ"}
    }
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    cond = "vim.fn.has('nvim-0.5.0')",
    config = function()
      require "_.treesitter"
    end
  },
  {
    "https://github.com/nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle"
  },
  -- }}}

  -- Syntax {{{
  {
    "https://github.com/norcalli/nvim-colorizer.lua",
    config = function()
      -- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
      require "colorizer".setup(
        {
          "*",
          "!vim"
        },
        {
          css = true
        }
      )
    end
  },
  {
    "https://github.com/plasticboy/vim-markdown",
    requires = {{"https://github.com/godlygeek/tabular"}}
  },
  {"https://github.com/jez/vim-github-hub"},
  {
    "https://github.com/fatih/vim-go",
    run = ":GoUpdateBinaries",
    opt = true,
    ft = {"go"}
  },
  -- Clojure
  {
    "https://github.com/junegunn/rainbow_parentheses.vim",
    ft = lisps,
    cmd = "RainbowParentheses",
    -- event = "InsertEnter *",
    config = "vim.cmd[[RainbowParentheses]]"
  },
  {"https://github.com/guns/vim-sexp", ft = lisps},
  {"https://github.com/Olical/conjure", tag = "v4.11.0", ft = lisps},
  -- {"https://github.com/sheerun/vim-polyglot"},
  -- }}}

  -- Linters & Code quality {{{
  {"https://github.com/dense-analysis/ale"},
  {
    "https://github.com/mhartington/formatter.nvim",
    config = function()
      local function prettier()
        return {
          exe = "prettier",
          args = {
            "--config-precedence",
            "prefer-file",
            "--single-quote",
            "--no-bracket-spacing",
            "--prose-wrap",
            "always",
            "--arrow-parens",
            "always",
            "--trailing-comma",
            "all",
            "--no-semi",
            "--end-of-line",
            "lf",
            "--print-width",
            vim.bo.textwidth,
            "--stdin-filepath",
            vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
          },
          stdin = true
        }
      end

      local function shfmt()
        return {
          exe = "shfmt",
          args = {"-"},
          stdin = true
        }
      end

      require "formatter".setup(
        {
          logging = false,
          filetype = {
            javascript = {prettier},
            typescript = {prettier},
            ["javascript.jsx"] = {prettier},
            ["typescript.tsx"] = {prettier},
            markdown = {prettier},
            css = {prettier},
            json = {prettier},
            scss = {prettier},
            less = {prettier},
            yaml = {prettier},
            graphql = {prettier},
            html = {prettier},
            sh = {shfmt},
            bash = {shfmt},
            reason = {
              function()
                return {
                  exe = "refmt",
                  stdin = true
                }
              end
            },
            rust = {
              function()
                return {
                  exe = "rustfmt",
                  args = {"--emit=stdout"},
                  stdin = true
                }
              end
            },
            python = {
              function()
                return {
                  exe = "black",
                  args = {"--quiet", "-"},
                  stdin = true
                }
              end
            },
            go = {
              function()
                return {
                  exe = "gofmt",
                  stdin = true
                }
              end
            },
            nix = {
              function()
                return {
                  exe = "nixfmt",
                  stdin = true
                }
              end
            },
            lua = {
              function()
                return {
                  exe = "luafmt",
                  args = {
                    "--indent-count",
                    2,
                    "-l",
                    vim.bo.textwidth,
                    "--stdin"
                  },
                  stdin = true
                }
              end
            }
          }
        }
      )
    end
  },
  -- }}}

  -- Git {{{
  {"https://github.com/lambdalisue/vim-gista"},
  {
    "https://github.com/tpope/vim-fugitive",
    requires = {
      {"https://github.com/tpope/vim-rhubarb"}
    }
  },
  {
    "https://github.com/rhysd/git-messenger.vim",
    opt = true,
    cmd = "GitMessenger",
    keys = "<Plug>(git-messenger)"
  },
  -- }}}

  -- Writing {{{
  {"https://github.com/junegunn/goyo.vim", opt = true, cmd = "Goyo"},
  {
    "https://github.com/junegunn/limelight.vim",
    opt = true,
    cmd = "Limelight"
  },
  -- }}}

  -- Themes, UI & eye cnady {{{
  {"https://github.com/andreypopp/vim-colors-plain", opt = true},
  {"https://github.com/liuchengxu/space-vim-theme", opt = true},
  {"https://github.com/rakr/vim-two-firewatch", opt = true},
  {"https://github.com/logico-dev/typewriter", opt = true},
  {"https://github.com/arzg/vim-substrata", opt = true},
  {"https://github.com/haishanh/night-owl.vim", opt = true},
  {"https://github.com/lifepillar/vim-gruvbox8", opt = true},
  {"https://github.com/bluz71/vim-moonfly-colors", opt = true},
  {"https://github.com/ulwlu/elly.vim", opt = true}
}

packer.init(
  {
    package_root = string.format("%s/pack", vim.fn.stdpath("config")),
    display = {
      open_cmd = "100vnew [packer]"
    }
  }
)

return packer.startup(
  function(use)
    for _, config in ipairs(plugins) do
      use(config)
    end
  end
)
