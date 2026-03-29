let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = ["kitty"];
        environment.extraInit = ''
          export TERMINFO_DIRS="$TERMINFO_DIRS:$KITTY_INSTALLATION_DIR/terminfo"
        '';
      };
    };

    nixos = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [kitty];
        environment.extraInit = ''
          export TERMINFO_DIRS="$TERMINFO_DIRS:${pkgs.kitty.terminfo}/share/terminfo"
        '';
      };
    };

    homeManager = _: {
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
