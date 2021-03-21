{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.kotlin;

in
{
  options = with lib; {
    my.modules.kotlin = {
      enable = mkEnableOption ''
        Whether to enable kotlin module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable { my.user = { packages = with pkgs; [ kotlin ktlint ]; }; };
}
