{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.bat;

in {
  options = with lib; {
    my.bat = {
      enable = mkEnableOption ''
        Whether to enable bat module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ bat ]; };

      home-manager = {
        users.${username} = {
          home = { file = { ".config/bat/config" = { source = ./config; }; }; };
        };
      };
    };
}
