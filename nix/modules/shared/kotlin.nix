{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.modules.kotlin;

in {
  options = with lib; {
    my.modules.kotlin = {
      enable = mkEnableOption ''
        Whether to enable kotlin module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ kotlin ktlint ]; };
    };
}
