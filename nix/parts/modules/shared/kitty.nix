let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = [ "kitty" ];
        environment.extraInit = ''
          export TERMINFO_DIRS="$TERMINFO_DIRS:$KITTY_INSTALLATION_DIR/terminfo"
        '';
      };
    };

    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          my.user.packages = with pkgs; [ kitty ];
          environment.extraInit = ''
            export TERMINFO_DIRS="$TERMINFO_DIRS:${pkgs.kitty.terminfo}/share/terminfo"
          '';
        };
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/kitty;
          sourceRoot = "${myConfig.dotfilesDir}/config/kitty";
          targetRoot = "kitty";
        };
      };
  };
in
{
  flake = {
    modules = {
      darwin.kitty = module.darwin;
      nixos.kitty = module.nixos;
      homeManager.kitty = module.homeManager;
    };
  };
}
