{ pkgs, lib, config, inputs, ... }:

with config.my;

let

  cfg = config.my.modules.helix;
in
{
  options = with lib; {
    my.modules.helix = {
      enable = mkEnableOption ''
        Whether to enable helix module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = {
        packages = with pkgs; [
          helix
        ];
      };

      my.hm.file = {
        ".config/helix" = {
          recursive = true;
          source = ../../../config/helix;
        };
      };

    };
}
