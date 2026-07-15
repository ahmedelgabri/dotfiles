let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = [ "ghostty@tip" ];
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
          my.user.packages = with pkgs; [ ghostty ];
        };
      };

    homeManager =
      { config, inputs, ... }:
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/ghostty;
            sourceRoot = "${config.home.homeDirectory}/.dotfiles/config/ghostty";
            targetRoot = "ghostty";
          }
          // {
            "ghostty/shaders" = {
              recursive = true;
              source = "${inputs.ghostty-cursor-shaders}";
            };
            "ghostty/config.nix.local" = {
              text = "custom-shader = shaders/cursor_tail.glsl";
            };
          };
      };
  };
in
{
  flake = {
    modules = {
      darwin.ghostty = module.darwin;
      nixos.ghostty = module.nixos;
      homeManager.ghostty = module.homeManager;
    };
  };
}
