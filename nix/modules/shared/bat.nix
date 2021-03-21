{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.bat;

in
{
  options = with lib; {
    my.modules.bat = {
      enable = mkEnableOption ''
        Whether to enable bat module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.env = { BAT_CONFIG_PATH = "$XDG_CONFIG_HOME/bat/config"; };

      my.user = { packages = with pkgs; [ bat ]; };

      my.hm.file = {
        ".config/bat" = {
          recursive = true;
          source = ../../../config/bat;
        };
      };
    };
}
