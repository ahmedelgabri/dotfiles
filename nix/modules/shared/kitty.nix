{ pkgs, lib, config, inputs, ... }:

with config.settings;

let

  cfg = config.my.kitty;

in {
  options = with lib; {
    my.kitty = {
      enable = mkEnableOption ''
        Whether to enable kitty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (mkIf pkgs.stdenv.isDarwin { homebrew.casks = [ "kitty" ]; })
      (mkIf pkgs.stdenv.isLinux {
        users.users.${username} = { packages = with pkgs; [ kitty ]; };
      })
      {
        environment.variables = {
          TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
        };

        home-manager = {
          users.${username} = {
            home = {
              file = {
                ".config/kitty" = {
                  recursive = true;
                  source = ../../../config/kitty;
                };
              };
            };
          };
        };
      }
    ]);
}
