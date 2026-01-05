{inputs, ...}: let
  batModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
      my.env = {BAT_CONFIG_PATH = "$XDG_CONFIG_HOME/bat/config";};

      my.user = {packages = with pkgs; [bat];};

      my.hm.file = {
        ".config/bat" = {
          recursive = true;
          source = ../../config/bat;
        };
      };
    };
  };
in {
  flake.modules.darwin.bat = batModule;
  flake.modules.nixos.bat = batModule;
}
