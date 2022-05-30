{ pkgs, lib, config, inputs, ... }:

with config.my;

let

  cfg = config.my.modules.vim;
  inherit (config.my.user) home;
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
          neovim
          ninja # used to build lua-language-server
        ] ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
          gcc # Requried for treesitter parsers
        ]);

      my.env = rec {
        EDITOR = "${pkgs.neovim}/bin/nvim";
        VISUAL = "$EDITOR";
        GIT_EDITOR = "$EDITOR";
        MANPAGER = "$EDITOR +Man!";
      };

      environment.shellAliases.e = "$EDITOR --listen /tmp/nvim.pipe";

      my.user = {
        packages = with pkgs; [
          fzf
          par
          fd
          ripgrep
          # editorconfig-checker # do I use it?
          hadolint # Docker linter
          nixpkgs-fmt
          vim-vint
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          stylua
          nodePackages.neovim
          nodePackages.vscode-langservers-extracted # HTML, CSS, JSON & ESLint LSPs
          nodePackages.prettier
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.typescript-language-server
          nodePackages.vim-language-server
          nodePackages.pyright
          nodePackages.yaml-language-server
          nodePackages."@tailwindcss/language-server"
          rnix-lsp
          selene # Lua linter
          statix
          nix-linter # Until statix pick up, see https://github.com/nerdypepper/statix/issues/18
          sumneko-lua-language-server
        ];
      };

      system.activationScripts.postUserActivation.text = ''
        echo ":: -> Running vim activationScript..."
        # Creating needed folders

        if [ ! -e "${home}/.local/share/nvim/undo" ]; then
          echo "Creating vim swap/backup/undo/view folders inside ${home}/.local/share/nvim ..."
          mkdir -p ${home}/.local/share/nvim/{backup,swap,undo,view}
        fi

        # Handle mutable configs

        if [ ! -e "${home}/.config/nvim/" ]; then
          echo "Linking vim folders..."
          ln -sf ${home}/.dotfiles/config/nvim ${home}/.config/nvim
        fi
      '';
    };
}
