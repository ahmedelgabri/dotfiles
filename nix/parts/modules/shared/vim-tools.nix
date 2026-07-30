# Tools neovim expects on its $PATH (LSP servers, linters, formatters and
# search helpers). Kept as a plain function so the host module (vim.nix) and
# the standalone wrapped neovim package (outputs/neovim.nix) share one list.
pkgs: with pkgs; [
  fzf
  fd
  ripgrep
  hadolint
  dotenv-linter
  nixfmt-rs
  shellcheck
  shfmt
  stylua
  vscode-langservers-extracted
  prettier
  bash-language-server
  dockerfile-language-server
  docker-compose-language-service
  docker-language-server
  vtsls
  yaml-language-server
  tailwindcss-language-server
  statix
  lua-language-server
  tree-sitter
  nixd
  taplo
  typos
  typos-lsp
  markdown-oxide
  copilot-language-server
  stylelint-lsp
]
