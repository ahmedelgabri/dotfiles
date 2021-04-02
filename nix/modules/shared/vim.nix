{ pkgs, lib, config, inputs, ... }:

with config.my;

let

  cfg = config.my.modules.vim;
  home = config.my.user.home;

in
{
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
          neovim-nightly
          ninja # used to build lua-language-server
        ] ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
          gcc # Requried for treesitter parsers
        ]);

      my.env = rec {
        EDITOR = "${pkgs.neovim-nightly}/bin/nvim";
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
          # editorconfig-checker # do I use it?
          proselint # ???
          nixpkgs-fmt
          vim-vint
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          nodePackages.neovim
          nodePackages.prettier
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.typescript-language-server
          nodePackages.vim-language-server
          # nodePackages.lua-fmt
          nodePackages.vscode-css-languageserver-bin
          neuron-notes
        ];
      };

      system.activationScripts.postUserActivation.text = ''
        echo ":: -> Running vim activationScript..."
        # Creating needed folders

        if [ ! -e "${home}/.local/share/nvim/swap" ]; then
          echo "Creating vim swap/backup/undo/view folders inside ${home}/.local/share/nvim ..."
          mkdir -p ${home}/.local/share/nvim/{backup,swap,undo,view}
        fi

        # Handle mutable configs

        if [ ! -e "${home}/.config/nvim" ]; then
          echo "Linking vim folders..."
          ln -sf ${home}/.dotfiles/config/.vim ${home}/.config/nvim
          ln -sf ${home}/.dotfiles/config/.vim ${home}/.vim
        fi
      '';
    };
}
