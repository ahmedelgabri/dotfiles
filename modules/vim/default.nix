{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.vim;

in {
  options = with lib; {
    my.vim = {
      enable = mkEnableOption ''
        Whether to enable vim module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ vim neovim-unwrapped ];
      environment.variables = {
        EDITOR = "${pkgs.neovim-unwrapped}/bin/nvim";
        VISUAL = "$EDITOR";
        GIT_EDITOR = "$EDITOR";
        MANPAGER = "${pkgs.neovim-unwrapped}/bin/nvim +Man!";
      };

      users.users.${username} = {
        packages = with pkgs; [
          fzf
          par
          fd
          ripgrep
          # editorconfig-checker # do I use it?
          proselint # ???
          yamllint
          hadolint # Docker linter
          nixfmt
          vim-vint
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          nodePackages.neovim
          nodePackages.prettier
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.ocaml-language-server
          nodePackages.typescript-language-server
          nodePackages.yaml-language-server
          nodePackages.vim-language-server
          # nodePackages.lua-fmt
          nodePackages.vscode-css-languageserver-bin
          nodePackages.vscode-json-languageserver-bin
        ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/nvim" = {
                recursive = true;
                source = ../../config/.vim;
              };
              ".vim" = {
                recursive = true;
                source = ../../config/.vim;
              };
            };
          };
        };
      };
    };
}
