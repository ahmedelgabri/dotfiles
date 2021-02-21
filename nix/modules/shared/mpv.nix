{ pkgs, lib, config, options, ... }:

with config.settings;

let

  cfg = config.my.mpv;

in {
  options = with lib; {
    my.mpv = {
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
