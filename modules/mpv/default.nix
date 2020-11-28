{ pkgs, lib, config, ... }:

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
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ mpv ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/mpv/mpv.conf" = { source = ./mpv.conf; };
              ".config/mpv/input.conf" = { source = ./input.conf; };
            };
          };
        };
      };
    };
}
