{ pkgs, lib, config, options, ... }:

with config.my;

let

  cfg = config.my.modules.mpv;

in {
  options = with lib; {
    my.modules.mpv = {
      enable = mkEnableOption ''
        Whether to enable mpv module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.casks = [ "mpv" ];
      } else {
        users.users.${username} = { packages = with pkgs; [ mpv ]; };
      })

      {
        home-manager = {
          users.${username} = {
            home = {
              file = {
                ".config/mpv" = {
                  recursive = true;
                  source = ../../../config/mpv;
                };
              };
            };
          };
        };
      }
    ]);
}
