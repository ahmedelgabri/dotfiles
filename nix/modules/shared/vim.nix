{ pkgs, lib, config, inputs, ... }:

with config.my;

let

  cfg = config.my.modules.vim;
  inherit (config.my.user) home;
  inherit (config.my) hm;
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
          neovim-unwrapped
        ] ++ (lib.optionals (!pkgs.stdenv.isDarwin) [
          gcc # Requried for treesitter parsers
        ]);

      my.env = {
        EDITOR = "${pkgs.neovim-unwrapped}/bin/nvim";
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
          dotenv-linter
          nixpkgs-fmt
          vim-vint
          shellcheck
          shfmt # Doesn't work with zsh, only sh & bash
          stylua
          nodePackages.vscode-langservers-extracted # HTML, CSS, JSON & ESLint LSPs
          nodePackages.prettier
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.typescript-language-server
          nodePackages.vim-language-server
          nodePackages.yaml-language-server
          nodePackages."@tailwindcss/language-server"
          selene # Lua linter
          statix
          sumneko-lua-language-server
          tree-sitter # required for treesitter "auto-install" option to work
          nil
        ];
      };

      system.activationScripts.postUserActivation.text = ''
        echo ":: -> Running vim activationScript..."
        # Creating needed folders

        if [ ! -e "${hm.stateHome}/nvim/undo" ]; then
          echo "Creating vim swap/backup/undo/view folders inside ${hm.stateHome}/nvim ..."
          mkdir -p ${hm.stateHome}/nvim/{backup,swap,undo,view}
        fi

        # Handle mutable configs

        if [ ! -e "${hm.configHome}/nvim/" ]; then
          echo "Linking vim folders..."
          ln -sf ${home}/.dotfiles/config/nvim ${hm.configHome}/nvim
        fi
      '';
    };
}
