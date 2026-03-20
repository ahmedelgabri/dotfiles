let
  module = {
    darwin = {
      lib,
      config,
      ...
    }: {
      config = with lib; {
        homebrew.casks = ["kitty"];
        my.env.TERMINFO_DIRS = [
          "$KITTY_INSTALLATION_DIR/terminfo"
        ];
      };
    };

    nixos = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [kitty];
        my.env.TERMINFO_DIRS = [
          "${pkgs.kitty.terminfo}/share/terminfo"
        ];
      };
    };

    homeManager = {
      lib,
      myConfig,
      ...
    }:
      with lib; {
        xdg.configFile."kitty" = {
          recursive = true;
          source = ../../../../config/kitty;
        };
      };
  };
in {
  flake = {
    modules = {
      darwin.kitty = module.darwin;
      nixos.kitty = module.nixos;
      homeManager.kitty = module.homeManager;
    };
  };
}
