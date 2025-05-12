{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.vim;
  inherit (config.my.user) home;
  inherit (config.my) hm;
in {
  options = with lib; {
    my.modules.vim = {
      enable = mkEnableOption ''
        Whether to enable vim module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs;
        [
          vim
          neovim-unwrapped
        ]
        ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
          gcc # Required for treesitter parsers
        ]);

      my.env = {
        EDITOR = "${pkgs.neovim-unwrapped}/bin/nvim";
        VISUAL = "$EDITOR";
        GIT_EDITOR = "$EDITOR";
        MANPAGER = "$EDITOR +Man!";
      };

      my.user = {
        packages = with pkgs; [
          fzf
          par
          fd
          ripgrep
          hadolint # Docker linter
          dotenv-linter
          alejandra
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          stylua
          vscode-langservers-extracted # HTML, CSS, JSON & ESLint LSPs
          nodePackages.prettier
          bash-language-server
          dockerfile-language-server-nodejs
          docker-compose-language-service
          vtsls # js/ts LSP
          yaml-language-server
          tailwindcss-language-server
          statix
          sumneko-lua-language-server
          tree-sitter # required for treesitter "auto-install" option to work
          nixd # nix lsp
          actionlint
          taplo # TOML linter and formatter
          selene # Lua linter
          # neovim luarocks support requires lua 5.1
          # https://github.com/folke/lazy.nvim/issues/1570#issuecomment-2194329169
          lua51Packages.luarocks
          typos
          typos-lsp
          copilot-language-server
          pngpaste # For Obsidian paste_img command
        ];
      };

      system.activationScripts.postUserActivation.text =
        /*
        bash
        */
        ''
          echo ":: -> Running vim activationScript..."
          # Handle mutable configs
          echo "Linking vim folders..."
          ln -sf ${home}/.dotfiles/config/nvim ${hm.configHome}

          echo "Creating vim swap/backup/undo/view folders inside ${hm.stateHome}/nvim ..."
          mkdir -p ${hm.stateHome}/nvim/{backup,swap,undo,view}
        '';
    };
}
