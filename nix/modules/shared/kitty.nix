{ pkgs, lib, config, options, ... }:

with config.settings;

let

  cfg = config.my.modules.kitty;

in {
  options = with lib; {
    my.modules.kitty = {
      enable = mkEnableOption ''
        Whether to enable kitty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.casks = [ "kitty" ];
      } else {
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
