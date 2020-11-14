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
    use {"https://github.com/wbthomason/packer.nvim", opt = true}

    use "https://github.com/antoinemadec/FixCursorHold.nvim"
    use "https://github.com/andymass/vim-matchup"
    use {"https://github.com/tpope/vim-sensible", opt = true}
    use "https://github.com/jiangmiao/auto-pairs"

    -- I have the bin globally, so don't build, and just grab plugin directory
    use {
      "https://github.com/junegunn/fzf.vim",
      requires = {{"https://github.com/junegunn/fzf"}}
    }

    use {
      "https://github.com/lambdalisue/fern-git.vim",
      requires = {{"https://github.com/lambdalisue/fern.vim"}}
    }
    use "https://github.com/duggiefresh/vim-easydir"
    use "https://github.com/junegunn/vim-peekaboo"
    use {
      "https://github.com/mbbill/undotree",
      opt = true,
      cmd = "UndotreeToggle"
    }
    use {"https://github.com/eugen0329/vim-esearch"}
    use {"https://github.com/mhinz/vim-sayonara", opt = true, cmd = "Sayonara"}
    use "https://github.com/mhinz/vim-startify"
    use "https://github.com/nelstrom/vim-visual-star-search"
    use "https://github.com/tpope/tpope-vim-abolish"
    use "https://github.com/tpope/vim-eunuch"
    -- use  'https://github.com/tpope/vim-projectionist'
    use "https://github.com/tpope/vim-repeat"
    use "https://github.com/machakann/vim-sandwich"
    use "https://github.com/tomtom/tcomment_vim"
    use "https://github.com/wellle/targets.vim"
    use "https://github.com/wincent/loupe"
    use "https://github.com/wincent/terminus"
    use "https://github.com/tommcdo/vim-lion"
    use "https://github.com/liuchengxu/vista.vim"
    use {"https://github.com/christoomey/vim-tmux-navigator", opt = true}
    use "https://github.com/rhysd/devdocs.vim"
    use "https://github.com/fcpg/vim-waikiki"
    -- }}}

    -- LSP/Autocompletion {{{
    use {
      "https://github.com/neovim/nvim-lspconfig",
      cond = "vim.fn.has('nvim-0.5.0')",
      config = function()
        vim.cmd [[lua require 'init']]
      end,
      requires = {
        {
          "https://github.com/tjdevries/lsp_extensions.nvim"
        }
      }
    }

    use {
      "https://github.com/nvim-lua/completion-nvim",
      requires = {
        {
          "https://github.com/steelsojka/completion-buffers",
          cond = "vim.fn.has('nvim-0.5.0')"
        },
        {"https://github.com/hrsh7th/vim-vsnip"},
        {"https://github.com/hrsh7th/vim-vsnip-integ"}
      }
    }
    -- }}}

    -- Syntax {{{
    use "https://github.com/norcalli/nvim-colorizer.lua"
    use {
      "https://github.com/plasticboy/vim-markdown",
      requires = {{"https://github.com/godlygeek/tabular"}}
    }
    use "https://github.com/jez/vim-github-hub"
    use {
      "https://github.com/fatih/vim-go",
      run = ":GoUpdateBinaries",
      opt = true,
      ft = {"go"}
    }
    -- Clojure
    local lisps = {"lisp", "scheme", "clojure"}
    use {
      "https://github.com/junegunn/rainbow_parentheses.vim",
      ft = lisps,
      cmd = "RainbowParentheses",
      -- event = "InsertEnter *",
      config = "vim.cmd[[RainbowParentheses]]"
    }
    use {"https://github.com/guns/vim-sexp", ft = lisps}
    use {"https://github.com/Olical/conjure", tag = "v4.8.0", ft = lisps}
    use "https://github.com/sheerun/vim-polyglot"
    -- }}}

    -- Linters & Code quality {{{
    use "https://github.com/dense-analysis/ale"
    use {
      "https://github.com/lukas-reineke/format.nvim",
      config = {
        [[
require "format".setup {
  lua = {
    {
      cmd = {
        function(file)
          return string.format("luafmt -i 2 -l %s -w replace %s", vim.bo.textwidth, file)
        end
      }
    }
  },
}
      ]]
      }
    }
    -- }}}

    -- Git {{{
    use "https://github.com/lambdalisue/vim-gista"
    use {
      "https://github.com/tpope/vim-fugitive",
      requires = {
        {"https://github.com/tpope/vim-rhubarb"}
      }
    }
    use {
      "https://github.com/rhysd/git-messenger.vim",
      opt = true,
      cmd = "GitMessenger",
      keys = "<Plug>(git-messenger)"
    }
    -- }}}

    -- Writing {{{
    use {"https://github.com/junegunn/goyo.vim", opt = true, cmd = "Goyo"}
    use {
      "https://github.com/junegunn/limelight.vim",
      opt = true,
      cmd = "Limelight"
    }
    -- }}}

    -- Themes, UI & eye cnady {{{
    use {"https://github.com/andreypopp/vim-colors-plain", opt = true}
    use {"https://github.com/liuchengxu/space-vim-theme", opt = true}
    use {"https://github.com/rakr/vim-two-firewatch", opt = true}
    use {"https://github.com/logico-dev/typewriter", opt = true}
    use {"https://github.com/arzg/vim-substrata", opt = true}
    use {"https://github.com/haishanh/night-owl.vim", opt = true}
    use {"https://github.com/lifepillar/vim-gruvbox8", opt = true}
    use {"https://github.com/bluz71/vim-moonfly-colors", opt = true}
  end
)
