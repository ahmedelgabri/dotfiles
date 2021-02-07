{ pkgs, lib, config, inputs, ... }:

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
      environment.systemPackages = with pkgs;
        [
          vim
          neovim-unwrapped
          ninja # used to build lua-language-server
        ] ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
          gcc # Requried for treesitter parsers
        ]);

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

      system.activationScripts.postUserActivation.text = ''
        echo ":: -> Running vim activationScript..."

        # Creating needed folders

        if [ ! -e "$HOME/.local/share/nvim/swap" ]; then
          echo "Creating vim swap/backup/undo/view folders inside $HOME/.local/share/nvim ..."
          mkdir -p $HOME/.local/share/nvim/{backup,swap,undo,view}
        fi

        # Handle mutable configs

        if [ ! -e "$HOME/.config/nvim" ]; then
          echo "Linking vim folders..."
          ln -sf $HOME/.dotfiles/config/.vim $HOME/.config/nvim
          ln -sf $HOME/.dotfiles/config/.vim $HOME/.vim
        fi
      '';
    };
}
