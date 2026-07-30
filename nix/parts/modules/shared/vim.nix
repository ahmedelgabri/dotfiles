let
  module =
    let
      commonModule =
        {
          pkgs,
          lib,
          ...
        }:
        {
          config = with lib; {
            environment = {
              shellAliases.e = "$EDITOR";

              systemPackages = with pkgs; [
                vim
                neovim-unwrapped
              ];
            };

            environment.variables = {
              EDITOR = "${lib.getExe pkgs.neovim-unwrapped}";
              VISUAL = "$EDITOR";
              GIT_EDITOR = "$EDITOR";
              MANPAGER = "$EDITOR +Man!";
            };

            my.user.packages = import ./vim-tools.nix pkgs;
          };
        };

      nixosModule =
        { pkgs, ... }:
        {
          imports = [ commonModule ];

          config = {
            environment.systemPackages = with pkgs; [ gcc ];
          };
        };
    in
    {
      darwin = commonModule;

      nixos = nixosModule;

      homeManager =
        {
          lib,
          config,
          ...
        }:
        {
          # Link the config out of the store so it stays live-editable without
          # a rebuild.
          xdg.configFile."nvim".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/nvim";

          home.activation.vim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo ":: -> Running vim home-manager activation..."
            mkdir -p ${config.xdg.stateHome}/nvim/{backup,swap,undo,view}
          '';
        };
    };
in
{
  flake = {
    modules = {
      darwin.vim = module.darwin;
      nixos.vim = module.nixos;
      homeManager.vim = module.homeManager;
    };
  };
}
