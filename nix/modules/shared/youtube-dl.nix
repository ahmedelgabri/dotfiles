{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.youtube-dl;

in {
  options = with lib; {
    my.modules.youtube-dl = {
      enable = mkEnableOption ''
        Whether to enable youtube-dl module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = { packages = with pkgs; [ youtube-dl ]; };

      my.hm.file = {
        ".config/youtube-dl" = {
          recursive = true;
          source = ../../../config/youtube-dl;
        };
      };
    };
}
