let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = ["ghostty@tip"];
      };
    };

    nixos = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [ghostty];
      };
    };

    homeManager = _: {
      xdg.configFile."ghostty" = {
        recursive = true;
        source = ../../../../config/ghostty;
      };
    };
  };
in {
  flake = {
    modules = {
      darwin.ghostty = module.darwin;
      nixos.ghostty = module.nixos;
      homeManager.ghostty = module.homeManager;
    };
  };
}
