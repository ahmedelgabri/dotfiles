let
  module = let
    commonModule = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        environment = {
          shellAliases.e = "$EDITOR";

          systemPackages = with pkgs; [
            vim
            neovim-unwrapped
          ];
        };

        my.env = {
          EDITOR = "${lib.getExe pkgs.neovim-unwrapped}";
          VISUAL = "$EDITOR";
          GIT_EDITOR = "$EDITOR";
          MANPAGER = "$EDITOR +Man!";
        };

        my.user.packages = with pkgs; [
          fzf
          fd
          ripgrep
          hadolint
          dotenv-linter
          alejandra
          shellcheck
          shfmt
          stylua
          vscode-langservers-extracted
          nodePackages.prettier
          bash-language-server
          dockerfile-language-server
          docker-compose-language-service
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
        ];
      };
    };

    nixosModule = {pkgs, ...}: {
      imports = [commonModule];

      config = {
        environment.systemPackages = with pkgs; [gcc];
      };
    };
  in {
    darwin = commonModule;

    nixos = nixosModule;

    homeManager = {
      lib,
      config,
      ...
    }: {
      home.activation.vim = lib.hm.dag.entryAfter ["writeBoundary"] ''
        echo ":: -> Running vim home-manager activation..."
        ln -sfn ${config.home.homeDirectory}/.dotfiles/config/nvim ${config.xdg.configHome}/nvim
        mkdir -p ${config.xdg.stateHome}/nvim/{backup,swap,undo,view}
      '';
    };
  };
in {
  flake = {
    modules = {
      darwin.vim = module.darwin;
      nixos.vim = module.nixos;
      homeManager.vim = module.homeManager;
    };
  };
}
