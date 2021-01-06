{ pkgs, lib, config, inputs, ... }:

with config.settings;

let

  cfg = config.my.ttrv;
  ttrv = pkgs.callPackage ../../pkgs/ttrv.nix { newSrc = inputs.ttrv; };

in {
  options = with lib; {
    my.ttrv = {
      enable = mkEnableOption ''
        Whether to enable ttrv module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ ttrv ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/ttrv" = {
                recursive = true;
                source = ../../../config/ttrv;
              };
            };
          };
        };
      };
    };
}
