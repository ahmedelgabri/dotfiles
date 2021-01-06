{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.hammerspoon;
  hammerspoon = pkgs.callPackage ../../pkgs/hammerspoon.nix { };

in {
  options = with lib; {
    my.hammerspoon = {
      enable = mkEnableOption ''
        Whether to enable hammerspoon module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ hammerspoon ];

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".hammerspoon" = {
                recursive = true;
                source = ../../../config/.hammerspoon;
              };
            };
          };
        };
      };
    };
}
